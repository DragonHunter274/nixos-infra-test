{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = true;
  networking.hostId = "a8c09e42"; # Required for ZFS - unique per host

  # GRUB bootloader (required for ZFS root)
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    enableCryptodisk = false;
    mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
    util-linux
  ];

  networking.hostName = "k3s-node2";
  networking.useDHCP = false;
  networking.interfaces.enp2s0 = {
    ipv4.addresses = [
      {
        address = "10.100.1.56";
        prefixLength = 16;
      }
    ];
  };
  networking.defaultGateway = "10.100.0.1";
  networking.nameservers = [ "10.100.0.1" ];

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";
  services.openssh.settings.MaxAuthTries = 10;


  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMrUsj8WPgNzTTEbt2/QXsEaJs/K9SuTbrqdgk0xSRC simon@thinkpad-simon"
  ];

  templates.services.k3s = {
    enable = true;
    serverAddr = "https://10.100.1.55:6443";
    tokenFile = "/var/lib/k3s/token";
    secretsEncryption = false;
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
