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
    ./home-packages.nix
  ];
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
  nixpkgs.config.segger-jlink.acceptLicense = true;
  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };

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

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake /home/simon/nixos-laptop/";
    };
    initExtra = ''
      # Update Kitty window title with current directory
      if [[ "$TERM" == "xterm-kitty" ]]; then
        # Append to PROMPT_COMMAND instead of replacing it
        PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND; }echo -ne '\033]0;''${PWD/#$HOME/~}\007'"
      fi
    '';
  };

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

  programs.git = {
    enable = true;
    userName = "DragonHunter274";
    userEmail = "schurgel@gmail.com";
  };

  home.file.".docker/config.json".text = builtins.toJSON {
    credHelpers = {
      "ghcr.io" = "ghcr-login";
    };
  };

  # You can access system configuration values via the systemConfig argument
  # For example:
  # programs.some-program.enable = systemConfig.services.some-service.enable;
}
