{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ ];

  # Bare metal Intel hardware kernel modules
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Filesystems are managed by disko - see disko-config.nix
  # disko will create the partitions and set up filesystems

  # Enable DHCP on all network interfaces by default
  networking.useDHCP = lib.mkDefault true;

  # Intel x86_64 platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Enable Intel microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
