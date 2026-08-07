# Example configuration showing how to use the desktop module
# This is how hosts/desktop-simon/configuration.nix would look after migration

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan
    ./hardware-configuration.nix

    # Import the desktop module
    ../../modules/desktop

    # Import other host-specific modules
    inputs.sops-nix.nixosModules.sops
    ./disko-config.nix
  ];
  disko.devices.disk.main.device = "/dev/nvme0n1";

  # Enable and configure the desktop environment
  desktop = {
    enable = true;
    user = "simon";
    homeStateVersion = "24.05";
    enabledPackageSets = [ "core" ];
    cinnamon = {
      enable = true;
    };

    # Additional system packages beyond defaults
    packages = with pkgs; [

    ];

    # Enable wireshark with NUR package
    wireshark = {
      enable = true;
      package = pkgs.nur-packages.wireshark;
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  # SOPS secrets configuration
  # sops.secrets."syncthing/key.pem" = {
  #   sopsFile = ./secrets/secrets.yaml;
  # };

  # sops.secrets."syncthing/cert.pem" = {
  #   sopsFile = ./secrets/secrets.yaml;
  # };





  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "35a61137";

  # Docker
  virtualisation.docker.enable = true;

  # Networking services
  services.tailscale.enable = true;

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "52b337794f63cd65"
    ];
  };

  # KDE Partition Manager
  programs.partition-manager.enable = true;

  # Avahi (mDNS)
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Power management
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  # Hostname
  networking.hostName = "t490s-simon";

  # Networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # User configuration
  users.users.simon = {
    isNormalUser = true;
    description = "simon";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
      "plugdev"
      "dialout"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # QEMU guest support
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Firefox
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;





  # SSH
  services.openssh.enable = true;

  # Firewall
  networking.firewall.enable = false;

  # NixOS state version
  system.stateVersion = "24.05";

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Development environment tools
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  services.lorri.enable = true;
}
