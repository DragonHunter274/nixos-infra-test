#!/usr/bin/env python3
"""Evaluate every nixosConfiguration and sync GitHub issues for eval warnings.

Nix/nixpkgs report evaluation problems on stderr in two shapes:
  warning: <single line>
  evaluation warning: <first line>
                       <indented continuation lines>

Each unique warning (by its full text) becomes one GitHub issue, labeled
"nix-eval-warning" and tagged with a stable hash marker in the body. Issues
are opened for new warnings and auto-closed once a warning stops appearing.
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


def main():
    repo = os.environ["GITHUB_REPOSITORY"]
    run_url = f"{os.environ['GITHUB_SERVER_URL']}/{repo}/actions/runs/{os.environ['GITHUB_RUN_ID']}"

    run(
        [
            "gh", "label", "create", LABEL,
            "--repo", repo,
            "--color", "FBCA04",
            "--description", "Automatically filed from a Nix evaluation warning",
        ],
        check=False,
    )  # ignore failure if the label already exists

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
                "--json", "number,body",
                "--limit", "200",
            ]
        ).stdout
    )
    open_map = {}
    for issue in open_issues:
        m = HASH_MARKER.search(issue.get("body") or "")
        if m:
            open_map[m.group(1)] = issue["number"]

    for h, text in warning_text.items():
        if h in open_map:
            continue
        hosts_list = ", ".join(sorted(warning_hosts[h]))
        title = f"Nix eval warning: {text.splitlines()[0][:80]}"
        body = (
            f"Nix evaluation warning detected on host(s): {hosts_list}\n\n"
            f"```\n{text}\n```\n\n"
            f"Detected in workflow run: {run_url}\n\n"
            "This issue is filed and closed automatically by the nix-eval-warnings "
            "workflow. It will be closed once the warning no longer appears during "
            "evaluation.\n\n"
            f"<!-- nix-eval-warning-hash: {h} -->\n"
        )
        print(f"Filing new issue for warning {h}: {title}")
        run(["gh", "issue", "create", "--repo", repo, "--title", title, "--body", body, "--label", LABEL])

    for h, number in open_map.items():
        if h in warning_text:
            continue
        print(f"Closing resolved issue #{number} for warning {h}")
        run(
            [
                "gh", "issue", "comment", str(number),
                "--repo", repo,
                "--body", f"This warning no longer appears as of workflow run {run_url}. Closing automatically.",
            ]
        )
        run(["gh", "issue", "close", str(number), "--repo", repo])


if __name__ == "__main__":
    main()
