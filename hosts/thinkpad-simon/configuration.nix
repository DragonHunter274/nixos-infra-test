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
    ./modules/nixos/fingerprint.nix
    ./modules/nixos/udev-mtkclient.nix
    ../common-desktop
    inputs.termfilepickers.nixosModules.default
  ];

  nix.buildMachines = [
    {
      hostName = "91.98.67.240";
      system = "aarch64-linux";
      protocol = "ssh";
      maxJobs = 8;
      speedFactor = 4;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      mandatoryFeatures = [ ];
      sshUser = "root";
      sshKey = "/home/simon/.ssh/id_ed25519";
    }
  ];
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  programs.adb.enable = true;

  #boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.kernelModules = [
    "sg"
  ];

  services.printing.drivers = [
    pkgs.hplip
    pkgs.samsung-unified-linux-driver
  ];

  services.flatpak.enable = true;

  services.udev.packages = [
    pkgs.openocd
    pkgs.stlink
  ];
  nix.settings.trusted-users = [ "@wheel" ];
  nixpkgs.config.permittedInsecurePackages = [
    "segger-jlink-qt4-796s"
  ];

  nixpkgs.config.segger-jlink.acceptLicense = true;
  #networking.networkmanager.settings."connection.ipv6.addr-gen-mode" = "eui64";
  #networking.networkmanager.settings."connection.ipv6.ip6-privacy" = "0";
  networking.networkmanager.settings.connection = {
    "ipv6.addr-gen-mode" = "eui64";
    "ipv6.ip6-privacy" = "0";
  };
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true;
  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.lldpd.enable = true;

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

  # services.xdg-desktop-portal-termfilepickers =
  #   let
  #     termfilepickers = inputs.termfilepickers.packages.${pkgs.system}.default;
  #   in
  #   {
  #     enable = true;
  #     package = termfilepickers;
  #     desktopEnvironments = [ "hyprland" ];
  #     config = {
  #       save_file_script_path = "${termfilepickers}/share/wrappers/yazi-save-file.nu";
  #       open_file_script_path = "${termfilepickers}/share/wrappers/yazi-open-file.nu";
  #       save_files_script_path = "${termfilepickers}/share/wrappers/yazi-save-file.nu";
  #       terminal_command = lib.getExe pkgs.kitty;
  #     };
  #   };

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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
  networking.hostName = "thinkpad-simon"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

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
      systemConfig = config;
    };
  };
  services.xserver.enable = true;
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.theme = "Elegant";
  services.displayManager.defaultSession = "hyprland";
  #services.desktopManager.plasma6.enable = true;
  #services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.simon = {
    isNormalUser = true;
    description = "simon";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "dialout"
      "cdrom"
      "adbusers"
      "plugdev"
    ];
    packages = with pkgs; [
      kdePackages.kate
      #  thunderbird
    ];
  };

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
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    nixfmt-rfc-style
    tlp
    goldwarden
    bitwarden-desktop
    kdePackages.qtsvg
    inputs.pyprland.packages."x86_64-linux".pyprland
    elegant-sddm
    xdg-utils
    android-tools
    go
    tinygo
    gcc
    stlink
    openocd
    adafruit-nrfutil
    distrobox
    (limesuite.override { withGui = true; })
    # nur-packages.openbeken-flasher
    # nur-packages.mtkclient
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

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
