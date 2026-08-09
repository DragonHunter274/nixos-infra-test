#!/usr/bin/env python3
"""Evaluate every nixosConfiguration and sync GitHub issues for eval warnings.

Nix/nixpkgs report evaluation problems on stderr in two shapes:
  warning: <single line>
  evaluation warning: <first line>
                       <indented continuation lines>

Each unique warning (by its full text) becomes one GitHub issue, labeled
"nix-eval-warning" plus one "host/<hostname>" label per affected host, and
tagged with a stable hash marker in the body. Issues are opened for new
warnings; as the set of affected hosts changes, host labels and the body are
updated and a comment records the change; the issue closes only once no host
shows the warning anymore.
"""

import hashlib
import json
import os
import re
import subprocess
import sys

LABEL = "nix-eval-warning"
WARNING_START = re.compile(r"^(warning|evaluation warning): ")
HASH_MARKER = re.compile(r"nix-eval-warning-hash: ([a-f0-9]+)")


def run(cmd, check=True):
    return subprocess.run(cmd, text=True, capture_output=True, check=check)


def host_label(host):
    return f"host/{host}"


def ensure_label(repo, name, description):
    run(
        [
            "gh", "label", "create", name,
            "--repo", repo,
            "--color", "FBCA04",
            "--description", description,
        ],
        check=False,
    )  # ignore failure if the label already exists


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
    return hashlib.sha256(text.encode()).hexdigest()[:12]


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


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    run_url = f"{os.environ['GITHUB_SERVER_URL']}/{repo}/actions/runs/{os.environ['GITHUB_RUN_ID']}"

    ensure_label(repo, LABEL, "Automatically filed from a Nix evaluation warning")

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

    open_issues = json.loads(
        run(
            [
                "gh", "issue", "list",
                "--repo", repo,
                "--label", LABEL,
                "--state", "open",
                "--json", "number,body,labels",
                "--limit", "200",
            ]
        ).stdout
    )
    open_map = {}  # hash -> {"number": int, "hosts": set(hostnames)}
    for issue in open_issues:
        m = HASH_MARKER.search(issue.get("body") or "")
        if not m:
            continue
        current_hosts = {
            name[len("host/"):]
            for label in issue.get("labels", [])
            for name in [label["name"]]
            if name.startswith("host/")
        }
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
        ensure_label(repo, host_label(host), f"Nix eval warning affects host {host}")

    for h in new_hashes:
        text = warning_text[h]
        affected_hosts = sorted(warning_hosts[h])
        title = f"Nix eval warning: {text.splitlines()[0][:80]}"
        body = build_body(h, text, warning_hosts[h], run_url)
        print(f"Filing new issue for warning {h}: {title}")
        cmd = ["gh", "issue", "create", "--repo", repo, "--title", title, "--body", body]
        for host in affected_hosts:
            cmd += ["--label", host_label(host)]
        cmd += ["--label", LABEL]
        run(cmd)

    for h, info in open_map.items():
        number = info["number"]
        old_hosts = info["hosts"]

        if h not in warning_text:
            print(f"Closing resolved issue #{number} for warning {h}")
            run(
                [
                    "gh", "issue", "comment", str(number),
                    "--repo", repo,
                    "--body", f"This warning no longer appears as of workflow run {run_url}. Closing automatically.",
                ]
            )
            run(["gh", "issue", "close", str(number), "--repo", repo])
            continue

        new_hosts = warning_hosts[h]
        if new_hosts == old_hosts:
            continue

        added = sorted(new_hosts - old_hosts)
        removed = sorted(old_hosts - new_hosts)
        print(f"Updating issue #{number} for warning {h}: +{added} -{removed}")

        cmd = [
            "gh", "issue", "edit", str(number),
            "--repo", repo,
            "--body", build_body(h, warning_text[h], new_hosts, run_url),
        ]
        if added:
            cmd += ["--add-label", ",".join(host_label(host) for host in added)]
        if removed:
            cmd += ["--remove-label", ",".join(host_label(host) for host in removed)]
        run(cmd)

        comment_lines = []
        if removed:
            comment_lines.append(f"No longer affects: {', '.join(removed)}.")
        if added:
            comment_lines.append(f"Now also affects: {', '.join(added)}.")
        comment_lines.append(f"Still open for: {', '.join(sorted(new_hosts))}.")
        comment_lines.append(f"Updated in workflow run: {run_url}")
        run(
            [
                "gh", "issue", "comment", str(number),
                "--repo", repo,
                "--body", "\n".join(comment_lines),
            ]
        )


if __name__ == "__main__":
    main()
