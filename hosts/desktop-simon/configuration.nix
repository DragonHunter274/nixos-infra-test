# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cachix.nix
    ./modules/nixos/hyprland.nix
    ./modules/nixos/libvirt.nix
    ../common-desktop
    #    ./modules/nixos/fingerprint.nix
    # inputs.termfilepickers.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    "${inputs."nixpkgs-25-05"}/nixos/modules/programs/goldwarden.nix"
  ];

  sops.secrets."syncthing/key.pem" = {
    sopsFile = ./secrets/secrets.yaml;
  };

  sops.secrets."syncthing/cert.pem" = {
    sopsFile = ./secrets/secrets.yaml;
  };

  hardware.usb.wakeupDisabled = [
    {
      # Logitech wireless mouse receiver
      vendor = "046d";
      product = "c539";
    }
  ];

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder

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

  services.flatpak.enable = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  networking.hostId = "35a61137";

  virtualisation.docker.enable = true;

  services.tailscale.enable = true;

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "52b337794f63cd65"
    ];
  };

  programs.partition-manager.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  ###TERMFILEPICKERS

  #imports = [ inputs.xdp-termfilepickers.nixosModules.default ];

  #  services.xdg-desktop-portal-termfilepickers =
  #    let
  #      termfilepickers = inputs.termfilepickers.Wpackages.${pkgs.system}.default;
  #    in
  #    {
  #      enable = true;
  #      package = termfilepickers;
  #      desktopEnvironments = [ "hyprland" ];
  #      config = {
  #        save_file_script_path = "${termfilepickers}/share/wrappers/yazi-save-file.nu";
  #        open_file_script_path = "${termfilepickers}/share/wrappers/yazi-open-file.nu";
  #        save_files_script_path = "${termfilepickers}/share/wrappers/yazi-save-file.nu";
  #        terminal_command = lib.getExe pkgs.kitty;
  #      };
  #    };

  xdg = {
    portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      # Apparently, this can cause issues and was removed in NixOS 24.11. TODO: add it on a per-service basis
      # gtkUsePortal = true;
      xdgOpenUsePortal = true;
    };
  };

  ###END_TERMFILEPICKERS
  environment.variables = {
    QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
  };

  # Bootloader.

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  boot.loader.efi.canTouchEfiVariables = true;
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
  networking.hostName = "desktop-simon"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.simon = import ./home.nix;
    backupFileExtension = "backup";
    # You can add extra configuration here that will be merged with home.nix
    extraSpecialArgs = {
      # Pass extra arguments to home.nix if needed
      inherit pkgs;
      inherit inputs;
      # You could pass other values from your system config
      # systemConfig = config;
    };
  };
  services.xserver.enable = true;
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "Elegant";

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

  programs.adb.enable = true;

  # Enable automatic login for the user.
  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "simon";
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  # Install firefox.
  programs.firefox.enable = true;
  # programs.firefox.preferences = {
  #   "widget.use-xdg-desktop-portal.file-picker" = 1;
  # };
  programs.goldwarden.enable = true;
  programs.goldwarden.package = inputs.nixpkgs-25-05.legacyPackages.${pkgs.system}.goldwarden;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
    ];
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
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
    gnumake
    go
    jq
    sdrangel
    limesuite
    # nur-packages.openbeken-flasher
    # nur-packages.mtkclient
  ];

  system.userActivationScripts = {
    stdio = {
      text = ''
        rm -f /home/simon/Android/Sdk/platform-tools/adb
        ln -s /run/current-system/sw/bin/adb /home/simon/Android/Sdk/platform-tools/adb
      '';
      deps = [
      ];
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

}
