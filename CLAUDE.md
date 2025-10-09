# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NixOS infrastructure management repository using Nix flakes with flake-parts for modular configuration. It manages multiple NixOS hosts including desktops, laptops, servers, and Raspberry Pi devices.

## Architecture

The repository is organized with a modular flake-parts structure:

- **flake.nix**: Main flake definition with inputs and outputs
- **parts/**: Modular flake components
  - `hosts.nix`: Host configuration definitions using helper functions
  - `lib.nix`: Builder functions for different host types (mkNixos, mkRaspberryPi, mkISO)
  - `dev-shells.nix`: Development environment with tools and helpful commands
  - `hydra.nix`: Hydra CI/CD configuration
- **hosts/**: Per-host configurations
  - `common/`: Shared configuration modules
  - Individual host directories with `configuration.nix` and `hardware-configuration.nix`
- **modules/**: Reusable NixOS modules (syncthing, k3s, etc.)
- **home/**: Home-manager configurations

## Host Types

The system supports three host types via builder functions in `parts/lib.nix`:
1. **mkNixos**: Standard x86_64/aarch64 hosts
2. **mkRaspberryPi**: Raspberry Pi with SD image generation 
3. **mkISO**: ISO installer images with SSH enabled

## Development Commands

Enter the development shell:
```bash
nix develop
```

### Building and Deployment

Deploy to a host:
```bash
nixos-rebuild switch --flake .#<hostname> --target-host <ip>
```

Build system configurations:
```bash
nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel
```

### Hydra Build Outputs

```bash
# NixOS systems
nix build .#hydraJobs.nixos.<hostname>

# Raspberry Pi SD images  
nix build .#hydraJobs.sdImages.<rpi-hostname>

# ISO installer images
nix build .#hydraJobs.isoImages.<hostname-iso>

# Netboot configurations
nix build .#hydraJobs.netboot.<hostname-netboot>
```

### ISO Images

Build ISO:
```bash
nix build .#nixosConfigurations.<hostname>-iso.config.system.build.isoImage
```
Output: `result/iso/*.iso`

### Netboot

Build netboot configuration:
```bash
nix build .#nixosConfigurations.<hostname>-netboot.config.system.build.netboot
```

Serve netboot (requires nix-netboot-serve):
```bash
nix-netboot-serve result/ --address 0.0.0.0
```
iPXE boot: `chain http://<server-ip>:3030/<hostname-netboot>/netboot.ipxe`

### Code Quality

Format code:
```bash
nix fmt
```

Check flake:
```bash
nix flake check
```

## Key Features

- **SOPS integration**: Secrets management with sops-nix
- **GitOps**: Automatic deployment via comin service
- **Home-manager**: User environment management
- **Disko**: Declarative disk partitioning
- **Multiple architectures**: x86_64-linux and aarch64-linux support
- **Overlays**: Custom package overlays including NUR packages

## Available Hosts

Current hosts defined in `parts/hosts.nix`:
- **fablabmuc-38c3**: Event infrastructure server
- **fablabmuc-38c3-minipc**: Mini PC for event
- **desktop-simon**: Desktop workstation  
- **thinkpad-simon**: Laptop with fingerprint sensor support
- **k3s-dev**: Kubernetes development server
- **fablabmuc-tv**: Raspberry Pi for displays

## Common Modules

Reusable modules in `modules/`:
- `syncthing.nix`: Syncthing file synchronization
- `k3s.nix`: Kubernetes cluster setup
- `nmimport.nix`: NetworkManager configuration import
- `usb-wakeup-disable.nix`: USB wakeup prevention

## Development Environment

The dev shell (parts/dev-shells.nix) includes:
- nixos-rebuild with monitoring (nix-output-monitor, nvd)
- Code formatting (nixfmt-rfc-style)  
- Secrets management (sops)
- Version control (git)
- Netboot serving (nix-netboot-serve)