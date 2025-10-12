{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # LXC containers don't need traditional filesystem declarations
  # Proxmox handles the storage

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
