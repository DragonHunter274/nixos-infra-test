{ config, pkgs, lib, ... }:
let
  primaryUsbId = "b501f1b9-7714-472c-988f-3c997f146a17";
  backupUsbId = "b501f1b9-7714-472c-988f-3c997f146a18";
in
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Specify the disk device for disko partitioning
  # Adjust this to match your actual disk device (e.g., /dev/sda, /dev/nvme0n1)
  disko.devices.disk.main.device = "/dev/nvme0n1";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "uas" "usbcore" "usb_storage" "vfat" "nls_cp437" "nls_iso8859_1" ];
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 222;
    hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMrUsj8WPgNzTTEbt2/QXsEaJs/K9SuTbrqdgk0xSRC simon@thinkpad-simon"
    ];
  };
  boot.initrd.postDeviceCommands = lib.mkBefore ''
    mkdir -m 0755 -p /key
    sleep 2
    mount -n -t vfat -o ro "$(findfs UUID=${primaryUsbId})" /key || mount -n -t vfat -o ro "$(findfs UUID=${backupUsbId})" /key
  '';

  boot.initrd.luks.devices.cryptroot = {
    device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";
    preLVM = false;
    allowDiscards = lib.mkForce true;
    keyFile = "/key/keyfile";
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

  networking.hostName = "tothemars";
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
    services.servicelb = false;
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
