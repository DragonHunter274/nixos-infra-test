{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HBLR-00000_S4GJNX0R538710";
        content = {
          type = "gpt";
          partitions = {
            ESP0 = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot0";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "pool";
              };
            };
          };
        };
      };

      nvme1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HBLR-00000_S4GJNX0R538729";
        content = {
          type = "gpt";
          partitions = {
            ESP1 = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot1";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "pool";
              };
            };
          };
        };
      };
    };

    bcachefs_filesystems = {
      pool = {
        type = "bcachefs_filesystem";
        mountpoint = "/";
        # Default replicas=1 (no blanket mirroring). k3s persistent volume
        # data is bumped to 2 replicas at runtime - see configuration.nix.
      };
    };
  };
}