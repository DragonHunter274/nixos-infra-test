{ nixpkgs, pulls ? "{}", declInput, ... }:
let
  pkgs = import nixpkgs { };
  
  # Only create main jobset for now - no PR handling
  jobsets = {
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
  
  # Simple debug info
  debug = {
    totalJobsets = builtins.length (builtins.attrNames jobsets);
    jobsetNames = builtins.attrNames jobsets;
  };
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    echo "=== Jobsets Debug ==="
    cat <<EOF
    ${builtins.toJSON debug}
    EOF
    
    echo "=== Generated Jobsets ==="
    cat >$out <<EOF
    ${builtins.toJSON jobsets}
    EOF
    
    echo "Contents:"
    cat $out
  '';
}