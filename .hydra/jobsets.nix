{ nixpkgs, declInput, ... }:

{
  main = {
    enabled = 1;
    hidden = false;
    description = "Main branch";
    nixexprinput = "src";
    nixexprpath = "flake.nix";
    checkinterval = 300;
    schedulingshares = 100;
    enableemail = false;
    emailoverride = "";
    keepnr = 10;
    inputs = {
      src = {
        type = "git";
        value = "https://github.com/dragonhunter274/nixos-infra-test.git main";
        emailresponsible = false;
      };
      nixpkgs = {
        type = "git";
        value = "https://github.com/NixOS/nixpkgs.git nixos-unstable";
        emailresponsible = false;
      };
    };
  };
}
