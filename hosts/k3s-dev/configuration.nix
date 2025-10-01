{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
    util-linux
  ];

  networking.hostName = "k3s-dev";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMrUsj8WPgNzTTEbt2/QXsEaJs/K9SuTbrqdgk0xSRC simon@thinkpad-simon"
  ];

  templates.services.k3s = {
    enable = true;
    services.flux = {
      enable = true;
      bootstrap-url = "https://github.com/dragonhunter274/home-ops//environments/dev?ref=dev";
    };
  };

  nix.settings = {
    trusted-users = [ "root" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = "auto";
    cores = 0; # Use all available cores
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://attic.dh274.com/dragonhunter274"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "dragonhunter274:YOJMbBYzAnReiYABcWPFDX0TYlQuO5R4W1jRgN2yN1k="
    ];
  };

  system.stateVersion = "25.05";
}
