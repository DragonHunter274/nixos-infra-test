{ config, pkgs, ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "35a61137";
  boot.zfs.extraPools = ["flash"];
}
