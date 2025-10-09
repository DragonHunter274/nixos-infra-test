{
  description = "system flake";
  
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-24-05.url = "nixpkgs/nixos-24.05";
    nixpkgs-25-05.url = "nixpkgs/nixos-25.05";
    nixpkgs-23-11.url = "nixpkgs/nixos-23.11";
    makemkv.url = "nixpkgs/cf9c59527b042f4502a7b4ea5b484bfbc4e5c6ca";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-netboot-serve.url = "github:DeterminateSystems/nix-netboot-serve";
    
    sops-nix.url = "github:Mic92/sops-nix";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:dragonhunter274/nur-packages";
    comin = {
      url = "github:dragonhunter274/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    pyprland.url = "github:hyprland-community/pyprland";
    hyprlock.url = "github:hyprwm/hyprlock";
    termfilepickers.url = "github:guekka/xdg-desktop-portal-termfilepickers";
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
      inputs.nixpkgs.follows = "nixpkgs-23-11";
    };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      
      imports = [
        ./parts/hosts.nix
        ./parts/hydra.nix
        ./parts/dev-shells.nix
      ];

      perSystem = { system, pkgs, ... }: {
        formatter = pkgs.nixfmt-rfc-style;
      };
    };
}
