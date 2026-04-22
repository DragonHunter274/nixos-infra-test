# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/configuration.nix
    #    inputs.sops-nix.nixosModules.sops
  ];

  disko.devices.disk.main.device = "/dev/nvme0n1";
  networking.hostName = "fablabmuc-38c3-minipc"; # Define your hostname.
  services.tailscale.enable = true;

  sops.secrets."syncthing/key.pem" = {
    sopsFile = ./secrets/secrets.yaml;
  };

  sops.secrets."syncthing/cert.pem" = {
    sopsFile = ./secrets/secrets.yaml;
  };

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder

  # SFTP-only chroot share
  users.groups.sftponly = { };
  services.openssh = {
    openFirewall = true;
    extraConfig = ''
      Match Group sftponly
        ForceCommand internal-sftp
        ChrootDirectory /srv/sftp-share
        AllowTcpForwarding no
        X11Forwarding no
    '';
  };
  systemd.tmpfiles.rules = [
    "d /srv/sftp-share 0755 root root -"
    "d /srv/sftp-share/data 0775 root sftponly -"
  ];

  services.syncthing = {
    enable = true;
    key = "/run/secrets/syncthing/key.pem";
    cert = "/run/secrets/syncthing/cert.pem";
    devices = {
      "desktop-simon" = {
        id = "VUCFNSU-BXPGRJH-QMXIPGU-7WRAMAS-SRYNVA7-BQXTFAH-XYNIM3W-EP5DCQZ";
      };
      "fablabmuc-38c3-minipc" = {
        id = "7RQNXJ6-TBATF3N-NZNQBEB-6XF4GAC-OG6VXJV-HVXBJ73-CGOXJFW-EPHDIAU";
      };
    };
  };
}
