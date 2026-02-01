# k3s-node2 Installation Guide

K3s server node joining an existing cluster at `10.100.1.55:6443`, installed via nixos-anywhere.

## Prerequisites

1. The existing k3s server (node1 at `10.100.1.55`) must be running with `--cluster-init` (embedded etcd)
2. The k3s cluster join token from node1 (found at `/var/lib/rancher/k3s/server/node-token`)
3. Boot the target machine with a NixOS live ISO (USB)

## Configuration

- **Disko**: ZFS mirror across two SSDs ([disko-config.nix](disko-config.nix))
- **Network**: Static IP `10.100.1.56/16`, gateway `10.100.0.1`
- **K3s**: Joins existing cluster as server node, secrets-encryption disabled
- **Bootloader**: GRUB with EFI support

### Disk Layout (ZFS Mirror)

Two 120GB SATA SSDs in a ZFS mirror (`rpool`):
- `ata-TS120GSSD220S_030811E9E26762210138`
- `ata-TS120GSSD220S_020811E9E267629E0200`

Each disk is partitioned as:
- **Boot**: 1MB BIOS boot (EF02)
- **ESP**: 1GB EFI System Partition (vfat)
- **ZFS**: Remaining space

ZFS datasets: `root` (`/`), `nix` (`/nix`), `var` (`/var`), `home` (`/home`)

## Installation

### Quick Install

```bash
./INSTALL.sh <installer-dhcp-ip>
```

The script will:
1. Prompt for the k3s join token
2. Run nixos-anywhere (as `nixos` user with sudo)
3. Prompt to remove USB media before reboot
4. Wait for the machine to come up at `10.100.1.56`
5. Push the join token and restart k3s

### Manual Install

```bash
nixos-anywhere --flake .#k3s-node2 nixos@<installer-ip> \
  --ssh-option "ForwardAgent=yes" \
  --build-on remote \
  --no-reboot
```

After install, remove USB media, then reboot. Push the token manually:
```bash
ssh root@10.100.1.56 'mkdir -p /var/lib/k3s && echo "YOUR_TOKEN" > /var/lib/k3s/token && chmod 600 /var/lib/k3s/token'
ssh root@10.100.1.56 'systemctl restart k3s'
```

## Post-Installation

After installation:
1. SSH: `ssh root@10.100.1.56`
2. Check k3s: `systemctl status k3s`
3. Verify cluster join: `k3s kubectl get nodes`

## Rebuilding

```bash
nixos-rebuild switch --flake .#k3s-node2 --target-host root@10.100.1.56
```
