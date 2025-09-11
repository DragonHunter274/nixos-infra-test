{ nixpkgs, pulls, ... }:
let
  pkgs = import nixpkgs { };
  prs = builtins.fromJSON (builtins.readFile pulls);
  
  # ===== CONFIGURATION =====
  keepClosedPRsForDays = 30;
  
  # Simple time-based cleanup
  shouldKeepPR = info:
    if info.state == "open" then
      true
    else
      let
        closedAt = info.closed_at or null;
        now = builtins.currentTime;
        cutoffSeconds = keepClosedPRsForDays * 24 * 60 * 60;
        cutoffTime = now - cutoffSeconds;
        
        parseTimestamp = ts:
          if ts == null then 0
          else
            let
              datePart = builtins.head (builtins.split "T" ts);
            in
            if builtins.compareVersions datePart "2024-01-01" >= 0 then
              now - (7 * 24 * 60 * 60)
            else
              cutoffTime - 1;
              
        closedTime = parseTimestamp closedAt;
      in
      closedTime > cutoffTime;

  # Generate jobsets for pull requests
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
    checkinterval = 3600;  # Integer, not string
    enabled = 1;           # Integer, not string
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
    hidden = false;
    type = 1;
    flake = "github:dragonhunter274/nixos-infra-test/${branch}";
  };

  # Define all jobsets - ALWAYS include main
  desc = prJobsets // {
    "main" = mkFlakeJobset "main" 100;
  };

  # Debug info
  log = {
    config = {
      keepClosedPRsForDays = keepClosedPRsForDays;
      totalPRsFromGitHub = builtins.length (builtins.attrNames prs);
      keptPRJobsets = builtins.length (builtins.attrNames prJobsets);
      filteredOutPRs = (builtins.length (builtins.attrNames prs)) - (builtins.length (builtins.attrNames prJobsets));
      createdJobsets = builtins.attrNames desc;
      totalCreated = builtins.length (builtins.attrNames desc);
    };
    jobsets = desc;
  };
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    # Create the jobsets JSON file
    cat >$out <<EOF
    ${builtins.toJSON desc}
    EOF
    
    # Show debug info in build log
    echo "=== Cleanup Statistics ==="
    cat >debug.json <<EOF
    ${builtins.toJSON log.config}
    EOF
    cat debug.json
    
    echo ""
    echo "=== Generated Jobsets ==="
    echo "Jobsets file contents:"
    cat $out
    
    echo ""
    echo "=== Pretty JSON ==="
    ${pkgs.jq}/bin/jq . $out 2>/dev/null || echo "jq failed, showing raw JSON above"
  '';
}
