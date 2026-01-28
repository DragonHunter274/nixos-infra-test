{
  config,
  pkgs,
  pkgs-unstable,
  pkgs-24-05,
  systemConfig ? { },
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
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

  #  home.file.".docker/config.json".text = builtins.toJSON {
  #    credsHelpers = {
  #      "ghcr.io" = "ghcr-login";
  #    };
  #  };

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

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name = "breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  # Packages to install
  home.packages = with pkgs; [
    git
    vim
    google-chrome
    swaynotificationcenter
    #jellyfin-media-player
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
    nur-packages.rofi-nixsearch
    # nur-packages.mtkclient  # broken
    texlivePackages.latexmk
  ];

  programs.atuin = {
    enable = true;
    #    flags = [ "--disable-up-arrow" ];
    enableBashIntegration = true;
    daemon.enable = true;
    settings = {
      dialect = "uk";
      enter_accept = true;
    };
  };

  # Program-specific configurations
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake /home/simon/nixos-laptop/";
    };
  };

  programs.git = {
    enable = true;
    userName = "DragonHunter274";
    userEmail = "schurgel@gmail.com";
  };
  # You can access system configuration values via the systemConfig argument
  # For example:
  # programs.some-program.enable = systemConfig.services.some-service.enable;
}
