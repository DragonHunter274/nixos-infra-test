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
  };
  outputs =
    { nixpkgs, ... }@inputs:
    let
      helpers = import ./flakeHelpers.nix inputs;
      inherit (helpers) mkMerge mkNixos;
    in
    mkMerge [
      {
        formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      }
      (mkNixos "fablabmuc-38c3" { } [ ])
      (mkNixos "fablabmuc-38c3-minipc" { } [ ])
      (mkNixos "desktop-simon" { } [ ])
    ];
}
