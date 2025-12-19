# Desktop Module

A comprehensive NixOS module that provides a complete desktop environment with Hyprland, including home-manager configuration for user-level customization.

## Features

- **Hyprland** compositor with customizable monitors and layout
- **SDDM** display manager with theme support
- **PipeWire** audio system
- **XDG Desktop Portal** with GTK portal
- **Home-manager integration** - automatically configures user environment including:
  - Hyprland configuration
  - Waybar status bar
  - Rofi application launcher
  - Nushell shell
  - GTK and Qt theming
  - Git configuration
  - Various desktop applications

## Usage

### Basic Setup

```nix
{
  imports = [
    ../modules/desktop.nix
  ];

  desktop = {
    enable = true;
    user = "simon";  # Required: username for home-manager

    git = {
      userName = "Your Name";
      userEmail = "your.email@example.com";
    };
  };
}
```

### Advanced Configuration

```nix
{
  desktop = {
    enable = true;
    user = "simon";
    homeStateVersion = "24.05";

    # Hyprland configuration
    hyprland = {
      enable = true;
      monitors = [
        "DP-2, 2560x1440, 1080x1083, 1"
        "DP-4, 1920x1080, 0x603, 1, transform, 1"
      ];
      layout = "master";
    };

    # Display manager
    displayManager = {
      enable = true;
      theme = "Elegant";
      autoLogin = {
        enable = false;
        user = "";
      };
    };

    # Audio
    audio.enable = true;

    # Printing
    printing.enable = true;

    # Locale settings
    locale = {
      default = "en_US.UTF-8";
      extra = {
        LC_ADDRESS = "de_DE.UTF-8";
        # ... other locale settings
      };
    };

    timeZone = "Europe/Berlin";

    # Features
    flatpak.enable = true;
    geoclue.enable = true;
    rtlsdr.enable = true;

    # NixOS helper
    nh = {
      enable = true;
      flakePath = "/home/simon/nixos-infra-test";
      cleanEnable = false;
    };

    # Tools
    yazi.enable = true;
    wireshark.enable = true;

    # XDG Portal
    xdgPortal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;
    };

    # Additional system packages
    packages = with pkgs; [
      gh
      gnumake
      btop
      # ... add more packages
    ];

    # Home-manager packages
    homePackages = with pkgs; [
      google-chrome
      signal-desktop
      vscode-fhs
      # ... add more packages
    ];

    # Git configuration
    git = {
      userName = "DragonHunter274";
      userEmail = "schurgel@gmail.com";
    };

    # Docker credential helpers
    docker.credentialHelpers = {
      "ghcr.io" = "ghcr-login";
    };
  };
}
```

## Module Structure

The module is organized into:

1. **NixOS System Configuration** - System-level services and settings
2. **Home-Manager Configuration** - User-level dotfiles and applications

### Included Home-Manager Modules

The desktop module automatically imports and configures:

- `modules/home-manager/hyprland.nix` - Hyprland window manager configuration
- `modules/home-manager/waybar.nix` - Status bar configuration
- `modules/home-manager/rofi.nix` - Application launcher
- `modules/home-manager/scripts.nix` - Custom shell scripts
- `modules/home-manager/nushell.nix` - Nushell shell configuration

## Options

### Required Options

- `desktop.enable` - Enable the desktop module
- `desktop.user` - Username for home-manager configuration

### Optional Options

See the module source code for a complete list of available options. All options have sensible defaults and can be overridden as needed.

## Example: Migrating from common-desktop

Before:
```nix
{
  imports = [
    ../common-desktop
  ];

  home-manager = {
    users.simon = import ./home.nix;
    # ... configuration
  };
}
```

After:
```nix
{
  imports = [
    ../../modules/desktop.nix
  ];

  desktop = {
    enable = true;
    user = "simon";
    git = {
      userName = "Your Name";
      userEmail = "your@email.com";
    };
  };
}
```

The module handles home-manager configuration automatically, so you no longer need to manually configure `home-manager.users`.

## Notes

- The module requires `inputs.hyprland` to be available in your flake for the latest Hyprland package
- Home-manager must be available as a module (usually imported in your flake configuration)
- The module uses relative paths for home-manager imports, ensure the module structure is preserved
