{ nixpkgs, pulls ? "{}", declInput, ... }:
let
  pkgs = import nixpkgs { };
  
  # Safely parse pulls input
  prs = if pulls == "{}" || pulls == "" then {} 
        else builtins.fromJSON (builtins.readFile pulls);
  
  # Simple PR jobsets - only open PRs, no complex time logic
  prJobsets = pkgs.lib.mapAttrs (num: info: {
    enabled = if info.state == "open" then 1 else 0;
    hidden = info.state != "open";
    description = "PR ${num}: ${builtins.substring 0 50 info.title}";  # Truncate long titles
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
    totalPRs = builtins.length (builtins.attrNames prs);
    openPRs = builtins.length (pkgs.lib.filterAttrs (_: info: info.state == "open") prs);
    totalJobsets = builtins.length (builtins.attrNames allJobsets);
    jobsetNames = builtins.attrNames allJobsets;
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