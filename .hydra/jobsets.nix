{ nixpkgs, declInput, ... }:
let
  pkgs = import nixpkgs { };
  
  # Minimal jobset definition
  jobsets = {
    "test" = {
      enabled = 1;
      hidden = false;
      description = "Test jobset";
      checkinterval = 3600;
      schedulingshares = 10;
      enableemail = false;
      emailoverride = "";
      keepnr = 1;
      type = 1;
      flake = "github:dragonhunter274/nixos-infra-test/main";
    };
  };
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    echo "Creating jobsets JSON..."
    cat >$out <<EOF
    ${builtins.toJSON jobsets}
    EOF
    echo "Generated JSON:"
    cat $out
  '';
}