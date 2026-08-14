
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan
    ./hardware-configuration.nix

    # Import the desktop module
    ../../modules/desktop

    # Import other host-specific modules
    inputs.sops-nix.nixosModules.sops
    ./disko-config.nix
  ];
  disko.devices.disk.main.device = "/dev/nvme0n1";


  home-manager.users.fablab.home.file.".config/cinnamon-monitors.xml".text = ''
    <monitors version="2">
      <configuration>
        <logicalmonitor>
          <x>0</x>
          <y>0</y>
          <scale>1.5</scale>
          <primary>yes</primary>
          <monitor>
            <monitorspec>
              <connector>DP-1</connector>
              <vendor>DEL</vendor>
              <product>DELL P2415Q</product>
              <serial>D8VXF916063B</serial>
            </monitorspec>
            <mode>
              <width>3840</width>
              <height>2160</height>
              <rate>59.997123718261719</rate>
            </mode>
          </monitor>
        </logicalmonitor>
      </configuration>
    </monitors>
  '';


  hardware.graphics.enable = true;

  # Enable and configure the desktop environment
  desktop = {
    enable = true;
    user = "fablab";
    homeStateVersion = "24.05";
    enabledPackageSets = [ "core" ];
    cinnamon = {
      enable = true;
    };

    # Additional system packages beyond defaults
    packages = with pkgs; [
      spotify-x11
      orca-slicer
      prusa-slicer
      freecad
      age-plugin-tpm-legacy
    ];

    # Enable wireshark with NUR package
    wireshark = {
      enable = true;
      package = pkgs.nur-packages.wireshark;
    };
  };

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  sops.secrets.login_keyring_base64 = {
    sopsFile = ./secrets/secrets.yaml;
    owner = "fablab";
  };


  system.activationScripts.restoreKeyring = {
    deps = [ "setupSecrets" "users" ];
    text = ''
      # `install -d -o -g` only sets ownership on the directory it's
      # given, NOT on any intermediate parents it has to create along the
      # way -- if ~/.local or ~/.local/share didn't already exist, they
      # were being silently left root-owned (this script runs as root),
      # which broke home-manager's own activation (runs as fablab, needs
      # to write directly under ~/.local) and took the whole graphical
      # session down with it. Chown the full chain explicitly instead.
      mkdir -p /home/fablab/.local/share/keyrings
      chown fablab:users /home/fablab/.local /home/fablab/.local/share /home/fablab/.local/share/keyrings
      chmod 700 /home/fablab/.local/share/keyrings
      ${pkgs.coreutils}/bin/base64 -d ${config.sops.secrets.login_keyring_base64.path} > /home/fablab/.local/share/keyrings/login.keyring
      chown fablab:users /home/fablab/.local/share/keyrings/login.keyring
      chmod 600 /home/fablab/.local/share/keyrings/login.keyring
    '';
  };

  sops.secrets.spotify_prefs = {
    sopsFile = ./secrets/secrets.yaml;
    owner = "fablab";
    group = "users";
  };

  systemd.user.services.restore-spotify-session = {
    description = "Restore Spotify prefs from SOPS secret";
    wantedBy = [ "graphical-session.target" ];
    script = ''
      mkdir -p $HOME/.config/spotify
      cp -f ${config.sops.secrets.spotify_prefs.path} $HOME/.config/spotify/prefs
      chmod 600 $HOME/.config/spotify/prefs
    '';
  };

  system.activationScripts.setupTpmForSopsNix.text = ''
    mkdir -p /etc/sops-nix
    ${pkgs.tpm2-tools}/bin/tpm2_nvread 0x1500016 -C o -o /etc/sops-nix/tpm-identity.txt
  '';

  system.activationScripts.setupSecrets.deps = [ "setupTpmForSopsNix" ];

  sops.age.keyFile = "/etc/sops-nix/tpm-identity.txt";
  sops.age.plugins = [ pkgs.age-plugin-tpm-legacy ];

  boot.kernelParams = [ "systemd.machine_id=438a1fca24b8455fb68e3d4b242ef51d" ];
  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "35a61137";

  # Docker
  virtualisation.docker.enable = true;

  # KDE Partition Manager
  programs.partition-manager.enable = true;

  # Avahi (mDNS)
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Power management
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  # Hostname
  networking.hostName = "tothemoon";

  # Networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # User configuration
  users.users.fablab = {
    isNormalUser = true;
    description = "fablab";
    extraGroups = [
      "networkmanager"
      "wireshark"
      "plugdev"
      "dialout"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # QEMU guest support
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Firefox
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # SSH
  services.openssh.enable = true;

  # Firewall
  networking.firewall.enable = false;

  # NixOS state version
  system.stateVersion = "24.05";

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Development environment tools
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  services.lorri.enable = true;
}
