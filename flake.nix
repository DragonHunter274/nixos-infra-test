{
  description = "system flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-24-05.url = "nixpkgs/nixos-24.05";
    nixpkgs-23-11.url = "nixpkgs/nixos-23.11";
    makemkv.url = "nixpkgs/cf9c59527b042f4502a7b4ea5b484bfbc4e5c6ca";
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
  outputs =
    { nixpkgs, ... }@inputs:
    let
      helpers = import ./flakeHelpers.nix inputs;
      inherit (helpers) mkFlakeWithHydra mkNixos mkRaspberryPi;
    in
    mkFlakeWithHydra [
      {
        formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
        formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-rfc-style;
      }
      (mkNixos "fablabmuc-38c3" { } [ ])
      (mkNixos "fablabmuc-38c3-minipc" { } [ ])
      (mkNixos "desktop-simon" { } [ ])
      (mkNixos "thinkpad-simon" { } [
        inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
        inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
      ])
      (mkRaspberryPi "fablabmuc-tv" { pi = import ./home/pi.nix; } [ ])
    ];
}
