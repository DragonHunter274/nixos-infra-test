{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.desktop;
in
{
  imports = [
    ./packages.nix
  ];
  options.desktop = {
    enable = mkEnableOption "desktop environment configuration";

    user = mkOption {
      type = types.str;
      description = "Username for home-manager configuration";
    };

    homeStateVersion = mkOption {
      type = types.str;
      default = "24.05";
      description = "Home Manager state version";
    };

    hyprland = {
      enable = mkEnableOption "Hyprland compositor" // {
        default = true;
      };

      withUWSM = mkOption {
        type = types.bool;
        default = true;
        description = "Enable UWSM support for Hyprland";
      };

      package = mkOption {
        type = types.package;
        default =
          if inputs ? hyprland then
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
          else
            pkgs.hyprland;
        description = "Hyprland package to use";
      };

      portalPackage = mkOption {
        type = types.package;
        default =
          if inputs ? hyprland then
            inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
          else
            pkgs.xdg-desktop-portal-hyprland;
        description = "XDG desktop portal package for Hyprland";
      };

      monitors = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "DP-2, 2560x1440, 1080x1083, 1"
          "DP-4, 1920x1080, 0x603, 1, transform, 1"
        ];
        description = "Monitor configuration for Hyprland";
      };

      layout = mkOption {
        type = types.str;
        default = "master";
        description = "Window layout for Hyprland";
      };
    };

    displayManager = {
      enable = mkEnableOption "display manager (SDDM)" // {
        default = true;
      };

      theme = mkOption {
        type = types.str;
        default = "Elegant";
        description = "SDDM theme to use";
      };

      autoLogin = {
        enable = mkEnableOption "automatic login";

        user = mkOption {
          type = types.str;
          default = "";
          description = "User to automatically log in";
        };
      };
    };

    audio = {
      enable = mkEnableOption "audio support (PipeWire)" // {
        default = true;
      };
    };

    printing = {
      enable = mkEnableOption "CUPS printing support" // {
        default = true;
      };
    };

    locale = {
      default = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        description = "Default locale";
      };

      extra = mkOption {
        type = types.attrsOf types.str;
        default = {
          LC_ADDRESS = "de_DE.UTF-8";
          LC_IDENTIFICATION = "de_DE.UTF-8";
          LC_MEASUREMENT = "de_DE.UTF-8";
          LC_MONETARY = "de_DE.UTF-8";
          LC_NAME = "de_DE.UTF-8";
          LC_NUMERIC = "de_DE.UTF-8";
          LC_PAPER = "de_DE.UTF-8";
          LC_TELEPHONE = "de_DE.UTF-8";
          LC_TIME = "de_DE.UTF-8";
        };
        description = "Extra locale settings";
      };
    };

    timeZone = mkOption {
      type = types.str;
      default = "Europe/Berlin";
      description = "System timezone";
    };

    flatpak = {
      enable = mkEnableOption "Flatpak support" // {
        default = true;
      };
    };

    geoclue = {
      enable = mkEnableOption "GeoClue2 location services" // {
        default = true;
      };
    };

    rtlsdr = {
      enable = mkEnableOption "RTL-SDR support" // {
        default = true;
      };
    };

    nh = {
      enable = mkEnableOption "nh (NixOS helper)" // {
        default = true;
      };

      flakePath = mkOption {
        type = types.str;
        default = "/home/simon/nixos-infra-test";
        description = "Path to the NixOS flake";
      };

      cleanEnable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic cleaning";
      };
    };

    yazi = {
      enable = mkEnableOption "Yazi file manager" // {
        default = true;
      };
    };

    wireshark = {
      enable = mkEnableOption "Wireshark network analyzer" // {
        default = true;
      };

      package = mkOption {
        type = types.package;
        default = pkgs.wireshark;
        description = "Wireshark package to use";
      };
    };

    xdgPortal = {
      enable = mkEnableOption "XDG desktop portal" // {
        default = true;
      };

      extraPortals = mkOption {
        type = types.listOf types.package;
        default = [ pkgs.xdg-desktop-portal-gtk ];
        description = "Extra portal packages to install";
      };

      xdgOpenUsePortal = mkOption {
        type = types.bool;
        default = true;
        description = "Use XDG portal for xdg-open";
      };
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        gh
        gnumake
        btop
      ];
      description = "Additional desktop packages to install";
    };

    homePackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        git
        vim
        google-chrome
        swaynotificationcenter
        networkmanagerapplet
        signal-desktop
        thunderbird
        github-desktop
        prismlauncher
        moonlight-qt
        vesktop
        prusa-slicer
        orca-slicer
        usbutils
        pavucontrol
        gparted
        lunarvim
        kdePackages.krdc
        dnsutils
        ripgrep
        jq
        neovim
        kicad
        roboto
        vscode-fhs
        inkscape
        mpv
        kubectl
        kubelogin-oidc
        sops
        texliveFull
        texlivePackages.latexmk
      ];
      description = "Home-manager packages to install";
    };

    git = {
      userName = mkOption {
        type = types.str;
        default = "";
        description = "Git user name";
      };

      userEmail = mkOption {
        type = types.str;
        default = "";
        description = "Git user email";
      };
    };

    docker = {
      credentialHelpers = mkOption {
        type = types.attrsOf types.str;
        default = {
          "ghcr.io" = "ghcr-login";
        };
        description = "Docker credential helpers configuration";
      };
    };
  };

  config = mkIf cfg.enable {
    # Printing
    services.printing.enable = mkIf cfg.printing.enable true;

    # Audio with PipeWire
    services.pulseaudio.enable = false;
    security.rtkit.enable = mkIf cfg.audio.enable true;
    services.pipewire = mkIf cfg.audio.enable {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # Location services
    services.geoclue2.enable = mkIf cfg.geoclue.enable true;

    # Flatpak
    services.flatpak.enable = mkIf cfg.flatpak.enable true;

    # Locale
    i18n.defaultLocale = cfg.locale.default;
    i18n.extraLocaleSettings = cfg.locale.extra;

    # Timezone
    time.timeZone = cfg.timeZone;

    # RTL-SDR
    hardware.rtl-sdr.enable = mkIf cfg.rtlsdr.enable true;

    # nh (NixOS helper)
    programs.nh = mkIf cfg.nh.enable {
      enable = true;
      clean.enable = cfg.nh.cleanEnable;
      flake = cfg.nh.flakePath;
    };

    # Yazi
    programs.yazi.enable = mkIf cfg.yazi.enable true;

    # Wireshark
    programs.wireshark = mkIf cfg.wireshark.enable {
      enable = true;
      package = cfg.wireshark.package;
    };

    # Polkit
    security.polkit.enable = true;

    # GNOME Keyring
    services.gnome.gnome-keyring.enable = true;

    # Docker credential helpers configuration
    environment.etc."docker/config.json".text = builtins.toJSON {
      credHelpers = cfg.docker.credentialHelpers;
    };

    # X Server (needed for display manager)
    services.xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    # Display Manager
    services.displayManager = mkIf cfg.displayManager.enable {
      sddm = {
        enable = true;
        theme = cfg.displayManager.theme;
      };
      autoLogin = mkIf cfg.displayManager.autoLogin.enable {
        enable = true;
        user = cfg.displayManager.autoLogin.user;
      };
    };

    # Hyprland
    programs.hyprland = mkIf cfg.hyprland.enable {
      enable = true;
      withUWSM = cfg.hyprland.withUWSM;
      package = cfg.hyprland.package;
      portalPackage = cfg.hyprland.portalPackage;
    };

    # XDG Desktop Portal
    xdg.portal = mkIf cfg.xdgPortal.enable {
      enable = true;
      extraPortals = cfg.xdgPortal.extraPortals;
      xdgOpenUsePortal = cfg.xdgPortal.xdgOpenUsePortal;
    };

    # Environment variables
    environment.variables = {
      QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
    };

    # Wayland session variables
    environment.sessionVariables = mkIf cfg.hyprland.enable {
      NIXOS_OZONE_WL = "1";
      WL_RENDERER_ALLOW_SOFTWARE = "1";
    };

    # System packages
    environment.systemPackages =
      cfg.packages
      ++ optional cfg.hyprland.enable pkgs.kitty
      ++ optional (cfg.docker.credentialHelpers ? "ghcr.io") (
        if pkgs ? nur-packages then
          pkgs.nur-packages.docker-credential-ghcr-login
        else
          pkgs.docker-credential-gcr
      );

    # Home Manager Configuration
    home-manager.users.${cfg.user} =
      {
        config,
        pkgs,
        inputs,
        ...
      }:
      {
        imports = [
          ./modules/home-manager/hyprland.nix
          ./modules/home-manager/waybar.nix
          ./modules/home-manager/rofi.nix
          ./modules/home-manager/scripts.nix
          ./modules/home-manager/nushell.nix
        ];

        home.stateVersion = cfg.homeStateVersion;
        programs.home-manager.enable = true;

        # Cursor theme
        home.pointerCursor = {
          gtk.enable = true;
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 16;
        };

        # GTK theme
        gtk = {
          enable = true;
          theme = {
            package = pkgs.flat-remix-gtk;
            name = "Flat-Remix-GTK-Grey-Darkest";
          };
          iconTheme = {
            package = pkgs.kdePackages.breeze-icons;
            name = "Breeze";
          };
          font = {
            name = "Sans";
            size = 11;
          };
        };

        # Qt theme
        qt = {
          enable = true;
          platformTheme.name = "kde";
          style = {
            name = "breeze";
            package = pkgs.kdePackages.breeze;
          };
        };

        # Atuin
        programs.atuin = {
          enable = true;
          enableBashIntegration = true;
          daemon.enable = true;
          settings = {
            dialect = "uk";
            enter_accept = true;
          };
        };

        # Bash
        programs.bash = {
          enable = true;
          shellAliases = {
            ll = "ls -l";
            update = "sudo nixos-rebuild switch --flake /home/simon/nixos-laptop/";
          };
        };

        # Git
        programs.git = mkIf (cfg.git.userName != "" && cfg.git.userEmail != "") {
          enable = true;
          userName = cfg.git.userName;
          userEmail = cfg.git.userEmail;
        };

        # Packages
        home.packages =
          cfg.homePackages
          ++ (with pkgs; [
            nur-packages.rofi-nixsearch
            nur-packages.mtkclient
          ]);
      };
  };
}
