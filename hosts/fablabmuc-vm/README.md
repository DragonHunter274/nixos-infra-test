# fablabmuc-vm Installation Guide

This host is configured for a KVM guest (libvirt/virt-install style, virtio-blk
disk bus, UEFI firmware) installed using nixos-anywhere.

## Prerequisites

1. Install nixos-anywhere on your local machine:
   ```bash
   nix-shell -p nixos-anywhere
   ```

2. Create the VM with UEFI firmware (OVMF) and a virtio-blk disk, then boot it
   from a NixOS live ISO with SSH access (or any Linux with root SSH access).

## Configuration

The host is configured with:
- **Disko**: Automatic disk partitioning ([disko-config.nix](disko-config.nix))
- **Hardware**: KVM guest, virtio-blk disk bus ([hardware-configuration.nix](hardware-configuration.nix))
- **Default disk**: `/dev/vda` (adjust in [configuration.nix](configuration.nix) if the VM uses virtio-scsi or emulated NVMe instead)

### Disk Configuration

By default, disko will partition the disk as follows:
- **Boot partition**: 1MB BIOS boot (EF02, unused under UEFI but kept for parity with other hosts)
- **ESP**: 1GB EFI System Partition (vfat)
- **Swap**: 8GB swap partition
- **Root**: Remaining space (ext4)

If the VM instead presents its disk over virtio-scsi or emulated NVMe, update
both the device path and the initrd kernel modules:

```nix
# configuration.nix
disko.devices.disk.main.device = "/dev/sda"; # virtio-scsi
# or
disko.devices.disk.main.device = "/dev/nvme0n1"; # emulated NVMe
```

```nix
# hardware-configuration.nix
boot.initrd.availableKernelModules = [
  "virtio_pci"
  "virtio_scsi" # instead of virtio_blk
  "usbhid"
  "sd_mod"
  "sr_mod"
];
```

## Installation

```bash
nixos-anywhere --flake .#fablabmuc-vm root@<vm-ip>
```

With a custom SSH key:

```bash
nixos-anywhere --flake .#fablabmuc-vm root@<vm-ip> \
  --ssh-key ~/.ssh/id_ed25519
```

## Post-Installation

After installation:

1. The VM will reboot automatically into the installed system.
2. SSH access will be available with the authorized keys configured in [configuration.nix](configuration.nix).
3. comin will start syncing from the `main` branch of this repository (GitOps).

## Building Locally

Test the configuration builds correctly:
```bash
nix build .#nixosConfigurations.fablabmuc-vm.config.system.build.toplevel
```

## Troubleshooting

### Disk Not Found

If nixos-anywhere can't find `/dev/vda`:
1. Boot into a live environment.
2. Run `lsblk` to identify the actual disk device (bus may differ depending on
   how the VM was defined — virtio-blk, virtio-scsi, or NVMe).
3. Update `disko.devices.disk.main.device` in [configuration.nix](configuration.nix)
   and the matching kernel module in [hardware-configuration.nix](hardware-configuration.nix)
   as shown above.

### Boot Fails After Install (no UEFI)

If the VM only has legacy BIOS firmware, switch the bootloader from
systemd-boot to GRUB with BIOS support, and drop the ESP/ mountpoint
requirement in [disko-config.nix](disko-config.nix).
