{ nixpkgs, pulls ? {}, declInput, ... }:
let
  pkgs = import nixpkgs { };
  
  # Now we know pulls is a set, let's see what's in it
  pullsDebug = {
    type = builtins.typeOf pulls;
    hasAttrs = pulls != {};
    attrNames = builtins.attrNames pulls;
    attrCount = builtins.length (builtins.attrNames pulls);
  };
  
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
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    echo "=== Pulls Structure ===" >&2
    cat >&2 <<EOF
    ${builtins.toJSON pullsDebug}
    EOF
    
    cat >$out <<EOF
    ${builtins.toJSON jobsets}
    EOF
  '';
}