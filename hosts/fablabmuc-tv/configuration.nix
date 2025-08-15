# hosts/rpi-example/configuration.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # System configuration
  system.stateVersion = "24.05";

  # Hostname
  networking.hostName = "fablabmuc-tv";

  # Enable networking
  networking = {
    wireless.enable = true;
    wireless.networks = {
      # Configure your WiFi networks here
      # "MyWiFi" = {
      #   psk = "password";
      # };
    };
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # User configuration
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
    ];
  };

  # Enable sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Console configuration
  console.enable = false;

  # Reduce journal size to save SD card space
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxRetentionSec=7day
  '';

  programs.hyprland.enable = true;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    rsync
    kitty
  ];

  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize nix store
  nix.settings.auto-optimise-store = true;

  # Reduce swapping to preserve SD card
  boot.kernel.sysctl = {
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };

  # Mount tmpfs for temporary files
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "nodev"
      "nosuid"
      "size=1G"
    ];
  };
}
