# Example configuration showing how to use the desktop module
# This is how hosts/desktop-simon/configuration.nix would look after migration

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
    ../../modules/goldwarden-legacy.nix
    ./disko-config.nix
  ];
  disko.devices.disk.main.device = "/dev/nvme0n1";

  # UWSM session for SDDM (needed for hypridle/hyprlock to start as systemd user services)
  services.displayManager.sessionPackages = [
    (
      (pkgs.makeDesktopItem {
        name = "uwsm-hyprland";
        desktopName = "Hyprland (uwsm)";
        exec = "uwsm start -N -5 -F /run/current-system/sw/bin/Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        type = "Application";
      }).overrideAttrs
      (old: {
        buildCommand = old.buildCommand + ''
          mkdir -p $out/share/wayland-sessions
          mv $out/share/applications/*.desktop $out/share/wayland-sessions/
        '';
        passthru.providedSessions = [ "uwsm-hyprland" ];
      })
    )
  ];
  # Enable and configure the desktop environment
  desktop = {
    enable = true;
    user = "simon";
    homeStateVersion = "24.05";

    # Hyprland configuration with custom monitors
    hyprland = {
      enable = true;
      monitors = [
        "eDP-1, 1920x1080, 0x0, 1"
        ", preferred, auto, 1, mirror"
      ];
      layout = "master";
    };
    # Git configuration
    git = {
      userName = "DragonHunter274";
      userEmail = "schurgel@gmail.com";
    };

    # Additional system packages beyond defaults
    packages = with pkgs; [
      cachix
      nixfmt-rfc-style
      tlp
      bitwarden-desktop
      kdePackages.qtsvg
      inputs.pyprland.packages."x86_64-linux".pyprland
      elegant-sddm
      xdg-utils
      android-tools
      distrobox
      android-studio
      clang
      cmake
      flutter
      ninja
      pkg-config
      go
      jq
      sdrangel
      limesuite
    ];

    # Enable wireshark with NUR package
    wireshark = {
      enable = true;
      package = pkgs.nur-packages.wireshark;
    };
  };

  # Insecure packages permission
  # nixpkgs.config.permittedInsecurePackages = [
  #   "qtwebengine-5.15.19"
  # ];

  # SOPS secrets configuration
  # sops.secrets."syncthing/key.pem" = {
  #   sopsFile = ./secrets/secrets.yaml;
  # };

  # sops.secrets."syncthing/cert.pem" = {
  #   sopsFile = ./secrets/secrets.yaml;
  # };

  # Disable the default goldwarden module to use legacy
  disabledModules = [
    "programs/goldwarden.nix"
  ];

  # Syncthing configuration
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

  services.syncthing = {
    enable = true;
    user = "simon";
    group = "users";
    dataDir = "/home/simon";
    key = "/run/secrets/syncthing/key.pem";
    cert = "/run/secrets/syncthing/cert.pem";
    devices = {
      "desktop-simon" = {
        id = "VUCFNSU-BXPGRJH-QMXIPGU-7WRAMAS-SRYNVA7-BQXTFAH-XYNIM3W-EP5DCQZ";
      };
      "fablabmuc-38c3-minipc" = {
        id = "7RQNXJ6-TBATF3N-NZNQBEB-6XF4GAC-OG6VXJV-HVXBJ73-CGOXJFW-EPHDIAU";
      };
      "thinkpad-simon" = {
        id = "VUCFNSU-BXPGRJH-QMXIPGU-7WRAMAS-SRYNVA7-BQXTFAH-XYNIM3W-EP5DCQZ";
      };
    };
    folders = {
      Projects = {
        path = "/home/simon/Projects";
        devices = [
          "thinkpad-simon"
        ];
        createFolder = false;
      };
    };
  };

  # ZFS support
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "35a61137";

  # Docker
  virtualisation.docker.enable = true;

  # Networking services
  services.tailscale.enable = true;

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "52b337794f63cd65"
    ];
  };

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
  networking.hostName = "t490s-simon";

  # Networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # User configuration
  users.users.simon = {
    isNormalUser = true;
    description = "simon";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "adbusers"
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

  # Goldwarden
  services.goldwarden-legacy.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # OBS Studio
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };

  # User activation scripts
  system.userActivationScripts = {
    stdio = {
      text = ''
        rm -f /home/simon/Android/Sdk/platform-tools/adb
        ln -s /run/current-system/sw/bin/adb /home/simon/Android/Sdk/platform-tools/adb
      '';
      deps = [ ];
    };
  };

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
