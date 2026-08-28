{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Specify the disk device for disko partitioning
  # KVM guest with virtio-blk bus -> /dev/vda. Adjust if the VM instead uses
  # virtio-scsi (/dev/sda) or emulated NVMe (/dev/nvme0n1).
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

  networking.hostName = "fablabmuc-vm";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  # Advertise shared printers via mDNS/DNS-SD. cupsd registers its own
  # service records over avahi's D-Bus API, which needs userServices
  # publishing enabled (not just publish.enable).
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMrUsj8WPgNzTTEbt2/QXsEaJs/K9SuTbrqdgk0xSRC simon@thinkpad-simon"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII5ysOCCkd6Me7t/Gx3CxLQ0tCfte3/gI1yXIWASG3Cc abc@webtop-689b4b4bb4-j9wnn"
  ];
  services.printing.drivers = [
    pkgs.hplip
    pkgs.samsung-unified-linux-driver
    (pkgs.writeTextDir "share/cups/model/brother_ql570_printer_en.ppd" (
      builtins.readFile ./brother_ql570_printer_en.ppd
    ))
  ];

  services.tscMe240 = {
    enable = true;
    address = "socket://10.100.163.75:9100";
    customSizes = [
      {
        name = "60x40";
        widthMm = 64;
        heightMm = 40;
      }
      {
        name = "50x30";
        widthMm = 53;
        heightMm = 30;
      }
    ];
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
