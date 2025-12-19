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
    ./cachix.nix

    # Import the desktop module
    ../../modules/desktop.nix

    # Import other host-specific modules
    ./modules/nixos/libvirt.nix
    inputs.sops-nix.nixosModules.sops
    ../../modules/goldwarden-legacy.nix
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
        "DP-2, 2560x1440, 1080x1083, 1"
        "DP-4, 1920x1080, 0x603, 1, transform, 1"
        "DP-3, 1920x1080, 3640x1083, 1, transform, 2"
        "HDMI-A-2, 1440x900, 1080x183, 1, transform, 2"
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
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19"
  ];

  # SOPS secrets configuration
  sops.secrets."syncthing/key.pem" = {
    sopsFile = ./secrets/secrets.yaml;
  };

  sops.secrets."syncthing/cert.pem" = {
    sopsFile = ./secrets/secrets.yaml;
  };

  # Disable the default goldwarden module to use legacy
  disabledModules = [
    "programs/goldwarden.nix"
  ];

  # USB wakeup configuration
  hardware.usb.wakeupDisabled = [
    {
      # Logitech wireless mouse receiver
      vendor = "046d";
      product = "c539";
    }
  ];

  # Syncthing configuration
  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";

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
  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.device = lib.mkDefault "/dev/nvme0n1";
  boot.loader.grub.useOSProber = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Power management
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  # Hostname
  networking.hostName = "desktop-simon";

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

  # ADB
  programs.adb.enable = true;

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
