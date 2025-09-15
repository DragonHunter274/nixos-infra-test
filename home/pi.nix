{ config, pkgs, ... }:

{
  # Basic user info
  home.username = "pi";
  home.homeDirectory = "/home/pi";
  home.stateVersion = "24.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Packages for the TV setup
  home.packages = with pkgs; [
    # Media/display tools
    firefox
    vlc
    mpv

    # System tools
    htop
    git
    wget
    curl

    # Development tools (if needed)
    vim
    nano
  ];

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Pi User";
    userEmail = "pi@fablabmuc-tv.local";
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
    };
  };

  # SSH configuration
  programs.ssh = {
    enable = true;
  };

  # TV-specific configurations
  home.sessionVariables = {
    # Set display for GUI applications
    DISPLAY = ":0";
  };

  # Auto-start applications for TV display (if using a desktop environment)
  # You can customize this based on your TV setup needs
}
