{
  description = "system flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-25-05.url = "nixpkgs/nixos-25.05";
    nixpkgs-23-11.url = "github:NixOS/nixpkgs/nixos-23.11";
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-netboot-serve = {
      url = "github:DeterminateSystems/nix-netboot-serve";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:dragonhunter274/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:dragonhunter274/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/71a1216abcc7031776630a6d88f105605c4dc1c9";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:DragonHunter274/pyprland/fix-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    termfilepickers = {
      url = "github:guekka/xdg-desktop-portal-termfilepickers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
      inputs.nixpkgs.follows = "nixpkgs-23-11";
    };
    hydra-tools = {
      url = "github:DragonHunter274/hydra-tools";
      # Don't follow nixpkgs - let hydra-tools use its own compatible version
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    snix = {
      url = "git+https://git.snix.dev/snix/snix?ref=canon";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./parts/hosts.nix
        ./parts/isos.nix
        ./parts/hydra.nix
        ./parts/dev-shells.nix
        ./parts/ipxe.nix
      ];

      perSystem =
        { system, pkgs, ... }:
        {
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
