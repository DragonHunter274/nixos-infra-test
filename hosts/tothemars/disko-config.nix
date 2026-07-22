# Disko configuration for the Tothemars host with encrypted root and swap
# This configuration will be used by nixos-anywhere to partition the disk
# Usage: Set the disk device in configuration.nix with:
#   disko.devices.disk.main.device = "/dev/sda"; # or /dev/nvme0n1, etc.
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "8G";
              content = {
                type = "luks";
                name = "cryptswap";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "swap";
                  resumeDevice = true;
                };
              };
            };
            root = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
