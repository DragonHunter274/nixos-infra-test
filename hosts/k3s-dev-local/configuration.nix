{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Specify the disk device for disko partitioning
  # Adjust this to match your actual disk device (e.g., /dev/sda, /dev/nvme0n1)
  disko.devices.disk.main.device = "/dev/sda";

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

  networking.hostName = "k3s-dev-local";
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
      url = "https://github.com/dragonhunter274/home-ops";
      branch = "dev";
      path = "./environments/dev";

      sopsAgeKeyFile = /root/.config/sops/age/keys.txt; # Optional, defaults to ~/.config/sops/age/keys.txt
    };
    services.servicelb = true;
    services.traefik = true;
    services.local-storage = true;
  };

  nix.settings = {
    trusted-users = [ "root" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = "auto";
    cores = 0; # Use all available cores
  };

  system.stateVersion = "25.05";
}
