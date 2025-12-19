{ pkgs, ... }:

{
  # Desktop system packages
  # These packages are installed system-wide and available to all users
  environment.systemPackages = with pkgs; [
    # CLI Tools
    gh # GitHub CLI
    gnumake # Build automation
    btop # System monitor

    # Development Tools
    git
    vim
    neovim

    # Utilities
    usbutils # USB device utilities
    dnsutils # DNS utilities (dig, nslookup, etc.)
    ripgrep # Fast grep alternative
    jq # JSON processor

    inputs.pyprland.packages."x86_64-linux".pyprland
    cachix
    nixfmt-rfc-style
    ninja
    pkg-config
    go
    jq
    # Add your additional packages here
  ];
}
