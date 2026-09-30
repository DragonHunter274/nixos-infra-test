{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vmnw.netboot;
  usbNetwork = config.vanilla-mobile.usb-gadget.network;
in
{
  options.vmnw.netboot = {
    enable = lib.mkEnableOption "USB NBD netboot";

    serverAddress = lib.mkOption {
      type = lib.types.str;
      default = usbNetwork.clientAddress;
      description = "Address of the NBD server on the USB network.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9999;
      description = "Port on which the host serves the root image via NBD.";
    };
  };

  config = lib.mkIf cfg.enable {
    # The NBD disk only appears after the host configures the USB-NCM link and
    # accepts the connection. Do not let systemd time out the fstab device job
    # while netboot-nbd is intentionally still retrying.
    fileSystems = {
      "/".options = lib.mkAfter [ "x-systemd.device-timeout=infinity" ];
      "/nix".options = lib.mkAfter [ "x-systemd.device-timeout=infinity" ];

      # The root image exported over NBD deliberately does not contain the
      # separate VFAT image that is used as /boot after a real installation.
      # Do not hold the entire host system (and consequently sshd) behind a
      # device that cannot exist during a netboot session.
      "/boot".enable = false;
    };

    # The initrd creates and binds the NCM gadget before mounting the NBD
    # root.  ConfigFS state survives switch-root, so starting the normal host
    # unit afterwards would try to create the same gadget directories again
    # and fail with "File exists".  Keep the initrd-created gadget alive.
    systemd.services.usb-gadget.enable = false;

    # usb-moded takes ownership of the same ConfigFS gadget at basic.target.
    # In a netboot it would repeatedly reset the NCM link that carries the
    # root filesystem, causing kernel NBD requests to hang and eventually fail
    # with EIO.
    services = {
      usb-moded.enable = lib.mkForce false;
      usb-moded-notify.enable = lib.mkForce false;
    };

    system.build.netbootAndroidBootImage =
      pkgs.runCommand "nixos-netboot-android-boot-image"
        {
          nativeBuildInputs = [
            pkgs.buildPackages.android-tools
            pkgs.buildPackages.gzip
          ];
        }
        ''
          mkdir -p "$out"

          kernel=${config.system.build.kernel}/${config.boot.kernelPackages.kernel.target}
          dtb=${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}
          ramdisk=${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}
          # A boot loader entry normally adds this itself.  Android's boot
          # image only has the literal command line supplied here, however.
          # Without it initrd-find-nixos-closure cannot locate /nixos-closure
          # after mounting the NBD root.
          cmdline=${lib.escapeShellArg (lib.concatStringsSep " " ([
            "init=${config.system.build.toplevel}/init"
          ] ++ config.boot.kernelParams))}

          # A raw arm64 Image is position-independent but still has a 512 KiB
          # text offset. Booting it in place from an Android image makes U-Boot
          # relocate it over the following ramdisk. Compression makes U-Boot
          # decompress it into the separately allocated kernel_addr_r instead.
          gzip --no-name --best --stdout "$kernel" > kernel.img.gz

          # These offsets are physical load-address fields in the Android
          # header, not file-layout offsets. Use Android's conventional
          # 0x10008000 kernel address: U-Boot recognizes it as the default and
          # decompresses the kernel to its runtime kernel address.
          # A zero base would encode 0x00008000, which this U-Boot treats as a
          # literal load address rather than an offset into SDM845 RAM.
          mkbootimg \
            --header_version 2 \
            --base 0x10000000 \
            --kernel_offset 0x8000 \
            --ramdisk_offset 0x1000000 \
            --tags_offset 0x100 \
            --second_offset 0x0 \
            --dtb_offset 0x01f00000 \
            --pagesize ${toString config.vanilla-mobile.deviceInfo.imageSectorSize} \
            --cmdline "$cmdline" \
            --kernel kernel.img.gz \
            --ramdisk "$ramdisk" \
            --dtb "$dtb" \
            --output "$out/nixos-netboot.img"

        '';

    boot.initrd = {
      kernelModules = [
        "nbd"
        "usb_f_ncm"
      ];
      # Include netconsole without loading it before usb0 exists. The service
      # below loads it with the USB-NCM-specific target once the interface has
      # an address.
      availableKernelModules = [ "netconsole" ];

      systemd.services = {
        netboot-usb-gadget = {
          description = "Create the USB NCM gadget for netboot";
          wantedBy = [ "initrd.target" ];
          requires = [
            "sys-kernel-config.mount"
            "modprobe@libcomposite.service"
          ];
          after = [
            "systemd-modules-load.service"
            "sys-kernel-config.mount"
            "modprobe@libcomposite.service"
          ];
          before = [ "netboot-usb-network.service" ];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            StandardOutput = "journal+console";
            StandardError = "journal+console";
            TimeoutStartSec = "70s";
          };
          path = [ pkgs.coreutils ];
          script = ''
            attempt=0
            until test -n "$(ls -A /sys/class/udc 2>/dev/null)"; do
              attempt=$((attempt + 1))
              if test "$attempt" -ge 600; then
                echo "netboot: no USB Device Controller appeared after 60 seconds" >&2
                exit 1
              fi
              sleep 0.1
            done

            ${config.systemd.services.usb-gadget.script}
          '';
        };

        netboot-usb-network = {
          description = "Configure the phone end of the USB netboot network";
          wantedBy = [ "initrd.target" ];
          requires = [ "netboot-usb-gadget.service" ];
          after = [ "netboot-usb-gadget.service" ];
          before = [ "netboot-nbd.service" ];
          unitConfig.DefaultDependencies = false;
          path = [
            pkgs.coreutils
            pkgs.iproute2
          ];
          serviceConfig = {
            Type = "oneshot";
            StandardOutput = "journal+console";
            StandardError = "journal+console";
            TimeoutStartSec = "130s";
          };
          script = ''
            attempt=0
            until ip link show usb0 >/dev/null 2>&1; do
              attempt=$((attempt + 1))
              if test "$attempt" -ge 120; then
                echo "netboot: usb0 did not appear after 120 seconds" >&2
                exit 1
              fi
              if test $((attempt % 15)) -eq 0; then
                echo "netboot: waiting for usb0 ($attempt seconds)" >&2
              fi
              sleep 1
            done

            ip link set usb0 up
            ip address replace ${usbNetwork.serverAddress}/24 dev usb0
          '';
        };

        netboot-netconsole = {
          description = "Send kernel crash logs to the netboot host";
          wantedBy = [ "initrd.target" ];
          requires = [ "netboot-usb-network.service" ];
          after = [ "netboot-usb-network.service" ];
          before = [ "netboot-nbd.service" ];
          unitConfig.DefaultDependencies = false;
          path = [ pkgs.kmod ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            StandardOutput = "journal+console";
            StandardError = "journal+console";
          };
          script = ''
            modprobe netconsole \
              'netconsole=r@${usbNetwork.serverAddress}/usb0,6666@${usbNetwork.clientAddress}/'
            echo "netboot: kernel logs are streaming to ${usbNetwork.clientAddress}:6666"
          '';
        };

        netboot-nbd = {
          description = "Attach the Btrfs root image from the netboot host";
          wantedBy = [ "initrd.target" ];
          requires = [ "netboot-usb-network.service" ];
          after = [ "netboot-usb-network.service" ];
          requiredBy = [ "initrd-root-device.target" ];
          before = [ "initrd-root-device.target" ];
          unitConfig.DefaultDependencies = false;
          path = [
            pkgs.coreutils
            pkgs.kmod
            pkgs.nbd
          ];
          serviceConfig = {
            Type = "oneshot";
            # The host may need time to notice the NCM device, configure it,
            # and start nbd-server. Keep retrying instead of letting systemd's
            # default start timeout turn a recoverable race into a boot failure.
            TimeoutStartSec = "infinity";
            StandardOutput = "journal+console";
            StandardError = "journal+console";
          };
          script = ''
            modprobe nbd
            attempt=0

            # Do not set nbd-client's per-request I/O timeout here. A timeout
            # such as `-t 10` turns a short USB-NCM pause into EIO at the block
            # layer, after which Btrfs aborts its transaction and remounts the
            # root read-only. The surrounding `timeout` is only for the
            # initial connection attempt; once attached, the kernel NBD client
            # must wait for the TCP connection to recover.
            until timeout 15s nbd-client ${cfg.serverAddress} ${toString cfg.port} /dev/nbd0 \
              -b ${toString config.vanilla-mobile.deviceInfo.imageSectorSize}
            do
              attempt=$((attempt + 1))
              echo "netboot: NBD connection attempt $attempt failed" >&2
              sleep 5
            done
          '';
        };
      };
    };
  };
}