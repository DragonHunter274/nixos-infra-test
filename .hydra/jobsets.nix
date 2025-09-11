{ nixpkgs, pulls ? "{}", declInput, ... }:
let
  pkgs = import nixpkgs { };
  
  # Safely parse pulls input
  rawPulls = if pulls == "{}" || pulls == "" then {} 
             else builtins.fromJSON (builtins.readFile pulls);
  
  # The pulls input might be a list or an attrset, handle both cases
  prs = if builtins.isList rawPulls then
          # Convert list to attrset using PR number as key
          builtins.listToAttrs (map (pr: {
            name = toString pr.number;
            value = pr;
          }) rawPulls)
        else rawPulls;
  
  # Simple PR jobsets - only open PRs, no complex time logic
  prJobsets = pkgs.lib.mapAttrs (num: info: {
    enabled = if (info.state or "unknown") == "open" then 1 else 0;
    hidden = (info.state or "unknown") != "open";
    description = "PR ${num}: ${builtins.substring 0 50 (info.title or "Unknown PR")}";
    checkinterval = 300;
    schedulingshares = 20;
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
    type = 1;
    flake = "github:dragonhunter274/nixos-infra-test/pull/${num}/head";
  }) prs;
  
  # Main branch jobset
  mainJobset = {
    "main" = {
      enabled = 1;
      hidden = false;
      description = "Build main branch";
      checkinterval = 300;
      schedulingshares = 100;
      enableemail = false;
      emailoverride = "";
      keepnr = 10;
      type = 1;
      flake = "github:dragonhunter274/nixos-infra-test/main";
    };
  };
  
  # Combine all jobsets
  allJobsets = prJobsets // mainJobset;
  
  # Debug info
  debug = {
    pullsType = builtins.typeOf rawPulls;
    totalPRs = builtins.length (builtins.attrNames prs);
    openPRs = builtins.length (pkgs.lib.filterAttrs (_: info: (info.state or "unknown") == "open") prs);
    totalJobsets = builtins.length (builtins.attrNames allJobsets);
    jobsetNames = builtins.attrNames allJobsets;
    prNumbers = builtins.attrNames prs;
  };
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    echo "=== Debug Info ==="
    cat <<EOF
    ${builtins.toJSON debug}
    EOF
    
    echo "=== Generated Jobsets ==="
    cat >$out <<EOF
    ${builtins.toJSON allJobsets}
    EOF
    
    echo "Generated jobsets file:"
    cat $out
  '';
}