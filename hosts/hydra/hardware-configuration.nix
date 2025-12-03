{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # LXC containers don't need traditional filesystem declarations
  # Proxmox handles the storage

  # Enable DHCP for network connectivity
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
