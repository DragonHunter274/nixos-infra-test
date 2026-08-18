{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  unstablePkgs = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.extend (
    import ./overlay.nix
  );
in
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

  home-manager.users.fablab =
    { lib, ... }:
    {
      home.file.".config/cinnamon-monitors.xml".text = ''
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

      home.file.".config/gtk-3.0/bookmarks".text = ''
        smb://nas.fablab.lan/FabNAS FabNAS
      '';

      home.activation.seedKdePlaces = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                PLACES="$HOME/.local/share/user-places.xbel"
                if [ ! -e "$PLACES" ]; then
                  $DRY_RUN_CMD mkdir -p "$(dirname "$PLACES")"
                  $DRY_RUN_CMD cat > "$PLACES" <<'EOF'
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE xbel>
        <xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdepriv="http://www.kde.org/kdepriv" xmlns:mime="http://www.freedesktop.org/standards/shared-mime-info">
         <info>
          <metadata owner="http://www.kde.org">
           <kde_places_version>4</kde_places_version>
          </metadata>
         </info>
         <bookmark href="file:///home/fablab">
          <title>Home</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="user-home"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/0</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="file:///home/fablab/Desktop">
          <title>Desktop</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="user-desktop"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/1</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="file:///home/fablab/Documents">
          <title>Documents</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-documents"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/2</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="file:///home/fablab/Downloads">
          <title>Downloads</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-downloads"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/3</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="file:///home/fablab/Music">
          <title>Music</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-music"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/6</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="file:///home/fablab/Pictures">
          <title>Pictures</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-pictures"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/7</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="file:///home/fablab/Videos">
          <title>Videos</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-videos"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/8</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="remote:/">
          <title>Network</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-network"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/4</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="trash:/">
          <title>Trash</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="user-trash"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/5</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="recentlyused:/files">
          <title>Recent Files</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="document-open-recent"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/9</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="recentlyused:/locations">
          <title>Recent Locations</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="folder-open-recent"/></metadata>
           <metadata owner="http://www.kde.org"><ID>1659123555/10</ID><isSystemItem>true</isSystemItem></metadata>
          </info>
         </bookmark>
         <bookmark href="smb://nas.fablab.lan/FabNAS">
          <title>FabNAS</title>
          <info>
           <metadata owner="http://freedesktop.org"><bookmark:icon name="network-workgroup"/></metadata>
          </info>
         </bookmark>
        </xbel>
        EOF
                fi
      '';
    };

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
      unstablePkgs.orca-slicer
      inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.prusa-slicer
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
    deps = [
      "setupSecrets"
      "users"
    ];
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

  system.activationScripts.restoreSpotifyPrefs = {
    deps = [
      "setupSecrets"
      "users"
    ];
    text = ''
      # Cinnamon (especially the Wayland session) doesn't reliably start
      # graphical-session.target, so a systemd --user service gated on it
      # never fired. Restore this at boot/switch time instead, same as
      # restoreKeyring above.
      mkdir -p /home/fablab/.config/spotify
      chown fablab:users /home/fablab/.config /home/fablab/.config/spotify
      cp -f ${config.sops.secrets.spotify_prefs.path} /home/fablab/.config/spotify/prefs
      chown fablab:users /home/fablab/.config/spotify/prefs
      chmod 600 /home/fablab/.config/spotify/prefs
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
    hashedPassword = "$y$j9T$DDR8KjEkMKP6pG/KI2tcz1$WFh9vFd14aQijTiVtobJlpdoxOHblQvdGQ0e9tLpjd6";
    extraGroups = [
      "networkmanager"
      "wheel"
      "wireshark"
      "plugdev"
      "dialout"
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMrUsj8WPgNzTTEbt2/QXsEaJs/K9SuTbrqdgk0xSRC simon@thinkpad-simon"
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
  services.openssh.settings.MaxAuthTries = 15;

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
