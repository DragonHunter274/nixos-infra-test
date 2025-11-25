# k3s-dev-local Installation Guide

This host is configured for bare metal Intel hardware installation using nixos-anywhere.

## Prerequisites

1. Install nixos-anywhere on your local machine:
   ```bash
   nix-shell -p nixos-anywhere
   ```

2. Ensure you have SSH access to the target machine

## Configuration

The host is configured with:
- **Disko**: Automatic disk partitioning ([disko-config.nix](disko-config.nix))
- **Hardware**: Intel x86_64 bare metal ([hardware-configuration.nix](hardware-configuration.nix))
- **K3s**: Kubernetes cluster with Flux GitOps
- **Default disk**: `/dev/sda` (adjust in [configuration.nix](configuration.nix) if needed)

### Disk Configuration

By default, disko will partition the disk as follows:
- **Boot partition**: 1MB BIOS boot (EF02)
- **ESP**: 1GB EFI System Partition (vfat)
- **Swap**: 8GB swap partition
- **Root**: Remaining space (ext4)

To use a different disk device (e.g., NVMe), edit [configuration.nix](configuration.nix):
```nix
disko.devices.disk.main.device = "/dev/nvme0n1";
```

## Installation

### Option 1: Install from Live ISO

1. Boot the target machine with a NixOS live ISO
2. Ensure network connectivity
3. From your local machine, run:
   ```bash
   nixos-anywhere --flake .#k3s-dev-local root@<target-ip>
   ```

### Option 2: Install from Existing Linux

If the target machine is running any Linux distribution:
```bash
nixos-anywhere --flake .#k3s-dev-local root@<target-ip>
```

### Option 3: Install with Custom SSH Key

```bash
nixos-anywhere --flake .#k3s-dev-local root@<target-ip> \
  --ssh-key ~/.ssh/id_ed25519
```

## Post-Installation

After installation:

1. The system will reboot automatically
2. SSH access will be available with the authorized key configured in [configuration.nix](configuration.nix)
3. K3s will start automatically and set up the cluster
4. Flux will sync from the configured Git repository

## Building Locally

Test the configuration builds correctly:
```bash
nix build .#nixosConfigurations.k3s-dev-local.config.system.build.toplevel
```

## Customization

### Change Disk Device

Edit [configuration.nix](configuration.nix):
```nix
disko.devices.disk.main.device = "/dev/nvme0n1";  # Change this
```

### Modify Partition Layout

Edit [disko-config.nix](disko-config.nix) to adjust partition sizes or add additional partitions.

### Update SSH Keys

Edit [configuration.nix](configuration.nix):
```nix
users.users.root.openssh.authorizedKeys.keys = [
  "your-ssh-public-key-here"
];
```

## Troubleshooting

### Disk Not Found

If nixos-anywhere can't find the disk:
1. Boot into a live environment
2. Run `lsblk` to identify disk devices
3. Update `disko.devices.disk.main.device` in [configuration.nix](configuration.nix)

### SSH Connection Failed

Ensure:
- Target machine is reachable via SSH
- Root login is permitted (temporarily enable if needed)
- SSH keys are properly configured

### Build Errors

Check the flake builds locally first:
```bash
nix flake check
nix build .#nixosConfigurations.k3s-dev-local.config.system.build.toplevel
```
