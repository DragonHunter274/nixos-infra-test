{
  description = "system flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-24-05.url = "nixpkgs/nixos-24.05";
    sops-nix.url = "github:Mic92/sops-nix";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur.url = "github:dragonhunter274/nur-packages";
    comin = {
      url = "github:nlewo/comin";
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
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      nur,
      disko,
      nixpkgs-24-05,
      home-manager,
      comin,
      pyprland,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-24-05 = nixpkgs-24-05.legacyPackages.${system};

      # Common modules for all systems
      commonModules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        comin.nixosModules.comin
        # Setup overlays
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = [
              (final: prev: { nur-packages = nur.packages.${system}; })
              (final: prev: { unstable = pkgs; })
            ];
          }
        )
        # Setup home-manager
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = {
            pkgs-unstable = pkgs;
            pkgs-24-05 = pkgs-24-05;
            inherit inputs;
          };
        }
        # Setup comin gitops
        (
          { ... }:
          {
            services.comin = {
              enable = true;
              remotes = [
                {
                  name = "origin";
                  url = "https://github.com/dragonhunter274/nixos-infra-test.git";
                  branches.main.name = "main";
                }
              ];
            };
          }
        )
      ];

      # Function to create a NixOS system with common configuration
      mkSystem =
        hostname:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
          ] ++ commonModules;
        };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

      nixosConfigurations = {
        fablabmuc-38c3 = mkSystem "fablabmuc-38c3";
        fablabmuc-38c3-minipc = mkSystem "fablabmuc-38c3-minipc";
        desktop-simon = mkSystem "desktop-simon";
      };
    };
}
