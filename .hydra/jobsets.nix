{ nixpkgs, pulls ? "default", declInput, ... }:
let
  pkgs = import nixpkgs { };
  
  # Try to safely inspect pulls without processing it
  pullsInfo = {
    type = builtins.typeOf pulls;
    isPath = builtins.typeOf pulls == "path";
    isString = builtins.typeOf pulls == "string"; 
    isSet = builtins.typeOf pulls == "set";
    isList = builtins.typeOf pulls == "list";
    # Only try toString if it's safe
    asString = if builtins.typeOf pulls == "string" || builtins.typeOf pulls == "path" 
               then toString pulls 
               else "cannot convert to string";
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
    echo "=== Pulls Debug ===" >&2
    cat >&2 <<EOF
    ${builtins.toJSON pullsInfo}
    EOF
    
    cat >$out <<EOF
    ${builtins.toJSON jobsets}
    EOF
  '';
}