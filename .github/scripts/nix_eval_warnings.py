#!/usr/bin/env python3
"""Evaluate every nixosConfiguration and sync issues for eval warnings.

Nix/nixpkgs report evaluation problems on stderr in two shapes:
  warning: <single line>
  evaluation warning: <first line>
                       <indented continuation lines>

Each unique warning (by its full text) becomes one issue, labeled
"nix-eval-warning" plus one "host/<hostname>" label per affected host, and
tagged with a stable hash marker in the body. Issues are opened for new
warnings; as the set of affected hosts changes, host labels and the body are
updated and a comment records the change; the issue closes only once no host
shows the warning anymore.

Works against both GitHub (via the `gh` CLI) and Forgejo (via its REST API,
since `gh` depends on GraphQL, which Forgejo doesn't expose). The backend is
picked automatically from GITHUB_SERVER_URL -- overridable via
ISSUE_TRACKER_BACKEND=github|forgejo for edge cases like GHES.
"""

import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

LABEL = "nix-eval-warning"
WARNING_START = re.compile(r"^(warning|evaluation warning): ")
HASH_MARKER = re.compile(r"nix-eval-warning-hash: ([a-f0-9]+)")
# Nix store paths are content-addressed, so the hash segment changes on every
# rebuild even when the warning itself is unchanged (e.g. a path derived from
# the flake's own checkout, or an interpolated package path). Strip just the
# hash + derivation name (never contains "/") before hashing, so the same
# warning keeps the same identity across runs; any real subdirectory path
# that follows (e.g. .../source/hosts/<hostname>/...) is left intact since
# that part is meaningful, not volatile.
STORE_PATH = re.compile(r"/nix/store/[0-9a-df-np-sv-z]{32}-[^/\s\"'()]*")


def run(cmd, check=True):
    return subprocess.run(cmd, text=True, capture_output=True, check=check)


def host_label(host):
    return f"host/{host}"


def get_hosts():
    proc = run(["nix", "eval", "--json", ".#nixosConfigurations", "--apply", "builtins.attrNames"])
    return json.loads(proc.stdout)


def eval_host_stderr(host):
    proc = run(
        ["nix", "eval", f".#nixosConfigurations.{host}.config.system.build.toplevel.drvPath", "--raw"],
        check=False,
    )
    sys.stderr.write(proc.stderr)
    return proc.stderr


def parse_warnings(stderr_text):
    """Split stderr into warning blocks; a block continues while lines stay indented."""
    warnings = []
    current = None
    for line in stderr_text.splitlines():
        if WARNING_START.match(line):
            if current is not None:
                warnings.append("\n".join(current).strip())
            current = [line]
        elif current is not None and (line[:1] in (" ", "\t") or line.strip() == ""):
            current.append(line)
        else:
            if current is not None:
                warnings.append("\n".join(current).strip())
                current = None
    if current is not None:
        warnings.append("\n".join(current).strip())
    # Not a config problem, just checkout state -- don't track it.
    return [w for w in warnings if not w.startswith("warning: Git tree")]


def warning_hash(text):
    normalized = STORE_PATH.sub("/nix/store/<hash>-…", text)
    return hashlib.sha256(normalized.encode()).hexdigest()[:12]


def build_body(h, text, hosts, run_url):
    hosts_list = ", ".join(sorted(hosts))
    return (
        f"Nix evaluation warning detected on host(s): {hosts_list}\n\n"
        f"```\n{text}\n```\n\n"
        f"Detected in workflow run: {run_url}\n\n"
        "This issue is filed and closed automatically by the nix-eval-warnings "
        "workflow. It will be closed once the warning no longer appears during "
        "evaluation.\n\n"
        f"<!-- nix-eval-warning-hash: {h} -->\n"
    )


class GitHubBackend:
    """Issue tracker backend for github.com / GHES, via the `gh` CLI."""

    def __init__(self, repo):
        self.repo = repo

    def ensure_label(self, name, description):
        run(
            [
                "gh", "label", "create", name,
                "--repo", self.repo,
                "--color", "FBCA04",
                "--description", description,
            ],
            check=False,
        )  # ignore failure if the label already exists

    def list_open_issues(self, label):
        raw = json.loads(
            run(
                [
                    "gh", "issue", "list",
                    "--repo", self.repo,
                    "--label", label,
                    "--state", "open",
                    "--json", "number,body,labels",
                    "--limit", "200",
                ]
            ).stdout
        )
        return [
            {
                "number": issue["number"],
                "body": issue.get("body") or "",
                "labels": [label["name"] for label in issue.get("labels", [])],
            }
            for issue in raw
        ]

    def create_issue(self, title, body, labels):
        cmd = ["gh", "issue", "create", "--repo", self.repo, "--title", title, "--body", body]
        for name in labels:
            cmd += ["--label", name]
        run(cmd)

    def edit_issue(self, number, body=None, add_labels=None, remove_labels=None):
        cmd = ["gh", "issue", "edit", str(number), "--repo", self.repo]
        if body is not None:
            cmd += ["--body", body]
        if add_labels:
            cmd += ["--add-label", ",".join(add_labels)]
        if remove_labels:
            cmd += ["--remove-label", ",".join(remove_labels)]
        run(cmd)

    def comment(self, number, body):
        run(["gh", "issue", "comment", str(number), "--repo", self.repo, "--body", body])

    def close_issue(self, number):
        run(["gh", "issue", "close", str(number), "--repo", self.repo])


class ForgejoBackend:
    """Issue tracker backend for Forgejo, via its REST API (no GraphQL available).

    Unlike GitHub, Forgejo's issue-label endpoints take label IDs, not names,
    so label names are resolved/created through a small cache.
    """

    PAGE_SIZE = 50

    def __init__(self, repo, server_url, token):
        self.owner, self.name = repo.split("/", 1)
        self.api_base = server_url.rstrip("/") + "/api/v1"
        self.token = token
        self._label_ids = None

    def _repo_path(self, suffix=""):
        return f"/repos/{self.owner}/{self.name}{suffix}"

    def _request(self, method, path, body=None):
        url = f"{self.api_base}{path}"
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Authorization", f"token {self.token}")
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")
        try:
            with urllib.request.urlopen(req) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            raise RuntimeError(f"{method} {url} failed: {e.code} {e.read().decode(errors='replace')}") from e

    def _paginated(self, path_fn):
        items = []
        page = 1
        while True:
            batch = self._request("GET", path_fn(page)) or []
            items.extend(batch)
            if len(batch) < self.PAGE_SIZE:
                return items
            page += 1

    def _load_labels(self):
        if self._label_ids is None:
            labels = self._paginated(
                lambda page: self._repo_path(f"/labels?limit={self.PAGE_SIZE}&page={page}")
            )
            self._label_ids = {label["name"]: label["id"] for label in labels}
        return self._label_ids

    def _label_ids_for(self, names):
        labels = self._load_labels()
        return [labels[name] for name in names]

    def ensure_label(self, name, description):
        labels = self._load_labels()
        if name in labels:
            return
        created = self._request(
            "POST", self._repo_path("/labels"),
            {"name": name, "color": "#FBCA04", "description": description},
        )
        labels[name] = created["id"]

    def list_open_issues(self, label):
        issues = self._paginated(
            lambda page: self._repo_path(f"/issues?state=open&type=issues&limit={self.PAGE_SIZE}&page={page}")
        )
        result = []
        for issue in issues:
            names = [l["name"] for l in issue.get("labels", [])]
            if label in names:
                result.append({"number": issue["number"], "body": issue.get("body") or "", "labels": names})
        return result

    def create_issue(self, title, body, labels):
        self._request(
            "POST", self._repo_path("/issues"),
            {"title": title, "body": body, "labels": self._label_ids_for(labels)},
        )

    def edit_issue(self, number, body=None, add_labels=None, remove_labels=None):
        if body is not None:
            self._request("PATCH", self._repo_path(f"/issues/{number}"), {"body": body})
        if add_labels:
            self._request(
                "POST", self._repo_path(f"/issues/{number}/labels"),
                {"labels": self._label_ids_for(add_labels)},
            )
        if remove_labels:
            labels = self._load_labels()
            for name in remove_labels:
                label_id = labels.get(name)
                if label_id is not None:
                    self._request("DELETE", self._repo_path(f"/issues/{number}/labels/{label_id}"))

    def comment(self, number, body):
        self._request("POST", self._repo_path(f"/issues/{number}/comments"), {"body": body})

    def close_issue(self, number):
        self._request("PATCH", self._repo_path(f"/issues/{number}"), {"state": "closed"})


def make_backend(repo, server_url):
    backend_name = os.environ.get("ISSUE_TRACKER_BACKEND")
    if not backend_name:
        backend_name = "github" if server_url.rstrip("/") == "https://github.com" else "forgejo"

    if backend_name == "github":
        return GitHubBackend(repo)
    if backend_name == "forgejo":
        token = os.environ.get("GH_TOKEN") or os.environ["GITHUB_TOKEN"]
        return ForgejoBackend(repo, server_url, token)
    raise ValueError(f"Unknown ISSUE_TRACKER_BACKEND: {backend_name!r}")


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    server_url = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    run_url = f"{server_url}/{repo}/actions/runs/{os.environ['GITHUB_RUN_ID']}"
    tracker = make_backend(repo, server_url)

    tracker.ensure_label(LABEL, "Automatically filed from a Nix evaluation warning")

    hosts = get_hosts()
    warning_hosts = {}  # hash -> set(hostnames)
    warning_text = {}  # hash -> full warning text

    for host in hosts:
        print(f"::group::Evaluating {host}")
        stderr_text = eval_host_stderr(host)
        for text in parse_warnings(stderr_text):
            h = warning_hash(text)
            warning_hosts.setdefault(h, set()).add(host)
            warning_text[h] = text
        print("::endgroup::")

    print(f"Found {len(warning_text)} unique warning(s) across {len(hosts)} host(s)")

    open_map = {}  # hash -> {"number": int, "hosts": set(hostnames)}
    for issue in tracker.list_open_issues(LABEL):
        m = HASH_MARKER.search(issue["body"])
        if not m:
            continue
        current_hosts = {name[len("host/"):] for name in issue["labels"] if name.startswith("host/")}
        open_map[m.group(1)] = {"number": issue["number"], "hosts": current_hosts}

    new_hashes = [h for h in warning_text if h not in open_map]
    hosts_needing_labels = {host for h in new_hashes for host in warning_hosts[h]}
    hosts_needing_labels |= {
        host
        for h in open_map
        if h in warning_text
        for host in warning_hosts[h] - open_map[h]["hosts"]
    }
    for host in sorted(hosts_needing_labels):
        tracker.ensure_label(host_label(host), f"Nix eval warning affects host {host}")

    for h in new_hashes:
        text = warning_text[h]
        affected_hosts = sorted(warning_hosts[h])
        title = f"Nix eval warning: {text.splitlines()[0][:80]}"
        body = build_body(h, text, warning_hosts[h], run_url)
        print(f"Filing new issue for warning {h}: {title}")
        tracker.create_issue(title, body, [LABEL] + [host_label(host) for host in affected_hosts])

    for h, info in open_map.items():
        number = info["number"]
        old_hosts = info["hosts"]

        if h not in warning_text:
            print(f"Closing resolved issue #{number} for warning {h}")
            tracker.comment(
                number,
                f"This warning no longer appears as of workflow run {run_url}. Closing automatically.",
            )
            tracker.close_issue(number)
            continue

        new_hosts = warning_hosts[h]
        if new_hosts == old_hosts:
            continue

        added = sorted(new_hosts - old_hosts)
        removed = sorted(old_hosts - new_hosts)
        # An issue that had no host labels yet predates this labeling scheme:
        # every currently-affected host looks "added" on its first backfill,
        # but nothing about the warning actually changed, so stay quiet.
        is_backfill = not old_hosts
        print(f"Updating issue #{number} for warning {h}: +{added} -{removed}")

        tracker.edit_issue(
            number,
            body=build_body(h, warning_text[h], new_hosts, run_url),
            add_labels=[host_label(host) for host in added] or None,
            remove_labels=[host_label(host) for host in removed] or None,
        )

        if is_backfill:
            continue

        comment_lines = []
        if removed:
            comment_lines.append(f"No longer affects: {', '.join(removed)}.")
        if added:
            comment_lines.append(f"Now also affects: {', '.join(added)}.")
        comment_lines.append(f"Still open for: {', '.join(sorted(new_hosts))}.")
        comment_lines.append(f"Updated in workflow run: {run_url}")
        tracker.comment(number, "\n".join(comment_lines))


if __name__ == "__main__":
    main()
