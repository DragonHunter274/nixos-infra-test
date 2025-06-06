{
  description = "system flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    makemkv.url = "nixpkgs/cf9c59527b042f4502a7b4ea5b484bfbc4e5c6ca";
    nixpkgs-23-11.url = "nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable"; # Add unstable input
    nixpkgs-24-05.url = "nixpkgs/nixos-24.05";
    sops-nix.url = "github:Mic92/sops-nix";
    nur.url = "github:dragonhunter274/nur-packages";
    hyprland.url = "github:hyprwm/Hyprland";
    pyprland.url = "github:hyprland-community/pyprland";
    hyprlock.url = "git+file:///home/simon/hyprlock";
    termfilepickers.url = "github:guekka/xdg-desktop-portal-termfilepickers";
    nixos-06cb-009a-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
      inputs.nixpkgs.follows = "nixpkgs-23-11";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-24-05,
      makemkv,
      sops-nix,
      nur,
      home-manager,
      pyprland,
      nixos-06cb-009a-fingerprint-sensor,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
      pkgs-24-05 = nixpkgs-24-05.legacyPackages.${system};
      pkgs-makemkv = import makemkv {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations = {
        thinkpad-simon = lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./configuration.nix
            sops-nix.nixosModules.sops
            nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
            nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
            (
              { pkgs, ... }:
              {
                nixpkgs.overlays = [
                  (final: prev: {
                    nur-packages = nur.packages.${system};
                  })
                  # Add an overlay for unstable packages
                  (final: prev: {
                    unstable = pkgs-unstable;
                  })
                  (final: prev: {
                    pkgs-makemkv = pkgs-makemkv;
                  })
                ];
              }
            )
            home-manager.nixosModules.home-manager
            {
              # Pass unstable packages to home-manager
              home-manager.extraSpecialArgs = {
                pkgs-unstable = pkgs-unstable;
                pkgs-24-05 = pkgs-24-05;
              };
            }
          ];
        };
      };
    };
}
