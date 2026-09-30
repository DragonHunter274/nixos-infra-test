{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      {
        devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HBLR-00000_S4GJNX0R538710" ];
        path = "/boot0";
      }
      {
        devices = [ "/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HBLR-00000_S4GJNX0R538729" ];
        path = "/boot1";
      }
    ];
  };

  boot.loader.efi.canTouchEfiVariables = false;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
    util-linux
  ];

  networking.hostName = "server-hetzner";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
    settings.MaxAuthTries = 10;
  };

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

      sopsAgeKeyFile = /root/.config/sops/age/keys.txt;
    };
    services.servicelb = false;
    services.traefik = true;
    services.local-storage = true;
  };

  systemd.services.bcachefs-k3s-pv-replicas = {
    description = "Set bcachefs data_replicas=2 on k3s persistent volume storage";
    wantedBy = [ "multi-user.target" ];
    before = [ "k3s.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/rancher/k3s/storage
      ${pkgs.bcachefs-tools}/bin/bcachefs setattr --data_replicas=2 -R /var/lib/rancher/k3s/storage
    '';
  };

  systemd.services.k3s = {
    after = [ "bcachefs-k3s-pv-replicas.service" ];
    wants = [ "bcachefs-k3s-pv-replicas.service" ];
  };

  nix.settings = {
    trusted-users = [ "root" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = "auto";
    cores = 0; 
  };

  system.stateVersion = "26.05";
}
