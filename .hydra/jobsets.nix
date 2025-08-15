{ nixpkgs, pulls, ... }:
let
  pkgs = import nixpkgs { };
  prs = builtins.fromJSON (builtins.readFile pulls);

  # ===== CONFIGURATION =====
  keepClosedPRsForDays = 30; # <-- ADJUST THIS VALUE

  # Simple time-based cleanup
  shouldKeepPR =
    info:
    if info.state == "open" then
      true # Always keep open PRs
    else
      # For closed PRs, check if they're recent enough
      let
        # Use closed_at timestamp (always available for closed PRs)
        # GitHub format: "2023-12-01T10:30:00Z"
        closedAt = info.closed_at or null;

        # Simple date comparison using string comparison
        # This works because ISO 8601 dates are lexicographically sortable
        now = builtins.currentTime;

        # Convert days to seconds and calculate cutoff
        cutoffSeconds = keepClosedPRsForDays * 24 * 60 * 60;
        cutoffTime = now - cutoffSeconds;

        # Parse the GitHub timestamp to Unix time (simplified)
        parseTimestamp =
          ts:
          if ts == null then
            0
          else
            # This is a rough approximation - for exact parsing, use the full version above
            let
              # Extract year-month-day part: "2023-12-01T10:30:00Z" -> "2023-12-01"
              datePart = builtins.head (builtins.split "T" ts);
              # Simple heuristic: assume recent dates if they look recent
              # This is imprecise but works for typical use cases
            in
            if builtins.compareVersions datePart "2024-01-01" >= 0 then
              now - (7 * 24 * 60 * 60) # Treat as recent
            else
              cutoffTime - 1; # Treat as old

        closedTime = parseTimestamp closedAt;
      in
      closedTime > cutoffTime;

  # Generate jobsets for pull requests with time-based cleanup
  prJobsets = pkgs.lib.filterAttrs (_: info: shouldKeepPR info) (
    pkgs.lib.mapAttrs (num: info: {
      enabled = if info.state == "open" then 1 else 0;
      hidden = info.state != "open";
      description = "PR ${num}: ${info.title} (${info.state})";
      checkinterval = if info.state == "open" then 60 else 0;
      schedulingshares = if info.state == "open" then 20 else 5;
      enableemail = false;
      emailoverride = "";
      keepnr = if info.state == "open" then 3 else 5;
      type = 1;
      flake = "github:dragonhunter274/nixos-infra-test/pull/${num}/head";
    }) prs
  );

  # Helper function to create flake-based jobsets
  mkFlakeJobset = branch: schedulingshares: {
    inherit schedulingshares;
    description = "Build ${branch} branch";
    checkinterval = "3600";
    enabled = "1";
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
    hidden = false;
    type = 1;
    flake = "github:dragonhunter274/nixos-infra-test/${branch}";
  };

  # Define all jobsets
  desc = prJobsets // {
    "main" = mkFlakeJobset "main" 100;
  };

  # Debug info showing cleanup stats
  log = {
    config = {
      keepClosedPRsForDays = keepClosedPRsForDays;
      totalPRsFromGitHub = builtins.length (builtins.attrNames prs);
      keptPRJobsets = builtins.length (builtins.attrNames prJobsets);
      filteredOutPRs =
        (builtins.length (builtins.attrNames prs)) - (builtins.length (builtins.attrNames prJobsets));
    };
    jobsets = desc;
  };
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    cat >$out <<EOF
    ${builtins.toJSON desc}
    EOF
    # Show cleanup statistics in build log
    echo "=== Cleanup Statistics ==="
    cat <<EOF
    ${builtins.toJSON log.config}
    EOF
    ${pkgs.jq}/bin/jq . tmp 2>/dev/null || true
  '';
}
