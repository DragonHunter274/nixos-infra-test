# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/configuration.nix
    # ./sops_fetch.nix
  ];
  disko.devices.disk.main.device = "/dev/sda";
  networking.hostName = "fablabmuc-38c3"; # Define your hostname.
  services.copyparty.enable = true;
}
