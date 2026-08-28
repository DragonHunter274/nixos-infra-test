{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = ["${modulesPath}/profiles/qemu-guest.nix" ];

  # KVM guest kernel modules (virtio-blk disk bus)
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  # Filesystems are managed by disko - see disko-config.nix
  # disko will create the partitions and set up filesystems

  # Enable DHCP on all network interfaces by default
  networking.useDHCP = lib.mkDefault true;

  # x86_64 platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
