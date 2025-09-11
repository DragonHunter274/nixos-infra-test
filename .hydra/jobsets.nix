{ nixpkgs, pulls ? "{}", declInput, ... }:
let
  pkgs = import nixpkgs { };
in
{
  jobsets = pkgs.runCommand "debug-pulls" { } ''
    echo "pulls type: ${builtins.typeOf pulls}" > $out
    echo "pulls value: ${toString pulls}" >> $out
  '';
}