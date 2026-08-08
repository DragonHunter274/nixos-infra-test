inputs:

let
  lib = inputs.nixpkgs.lib;

  # -------------------------
  # Common modules
  # -------------------------
  commonModules = system: [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.comin.nixosModules.comin

    ../modules/usb-wakeup-disable
    ../modules/binary-caches

    # overlays
    (
      { ... }:
      {
        nixpkgs.overlays = [
          (final: prev: {
            nur-packages = inputs.nur.packages.${system} or { };
          })
          (final: prev: {
            unstable = inputs.nixpkgs.legacyPackages.${system};
          })
        ];
      }
    )

    inputs.home-manager.nixosModules.home-manager
  ];

  # -------------------------
  # Comin
  # -------------------------
  cominModule = hostname: {
    services.comin = {
      enable = true;
      hostname = hostname;
      remotes = [
        {
          name = "origin";
          url = "https://github.com/dragonhunter274/nixos-infra-test.git";
          branches.main.name = "main";
        }
      ];
    };
  };

  # -------------------------
  # Home-manager helper
  # -------------------------
  homeManagerCfg = system: extraUsers: {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.extraSpecialArgs = {
      pkgs-unstable = inputs.nixpkgs.legacyPackages.${system};
      pkgs-24-05 = inputs.nixpkgs-24-05.legacyPackages.${system};
      inherit inputs;
    };

    home-manager.users = extraUsers;
  };

  # -------------------------
  # Raspberry Pi modules
  # -------------------------
  rpiModules = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"

    (
      { ... }:
      {
        boot.loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };

        fileSystems."/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };

        sdImage.compressImage = true;
      }
    )
  ];

  # -------------------------
  # Netboot modules
  # -------------------------
  netbootModules = [
    "${inputs.nixpkgs}/nixos/modules/installer/netboot/netboot-minimal.nix"

    (
      { lib, ... }:
      {
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

        # Override disk-related config from host configurations
        # disko and hardware-configuration set these at default priority,
        # but netboot-minimal's mkImageMediaOverride (priority 60) may not
        # win against disko. Force-disable everything disk-related.
        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
        boot.resumeDevice = lib.mkForce "";
        disko.devices = lib.mkForce { };
        swapDevices = lib.mkForce [ ];
      }
    )
  ];

  # -------------------------
  # Netboot-over-NFS modules
  # -------------------------
  # Same idea as netbootModules above, but for full-sized (e.g. desktop)
  # closures that don't fit in a netbooting client's RAM: instead of
  # netboot.nix's default squashfs-loop mount of "/nix/.ro-store" (the
  # whole closure embedded in and downloaded as part of the initrd itself),
  # this NFS-mounts it from `nfsServer` at boot, so the client only pulls in
  # what it actually reads at runtime. Deliberately imports the *full*
  # netboot.nix, not netboot-minimal.nix -- unlike netbootModules above this
  # is meant to keep a real desktop system's full profile (NetworkManager,
  # sound, docs, etc.) intact, not trim it down.
  #
  # Design + the one non-obvious gotcha (flushBeforeStage2) confirmed
  # against https://xyno.space/posts/nix-store-nfs/ -- without it, stage-1
  # tears networking down before the NFS mount below is used, and boot
  # hangs silently forever (~10h to debug per that post). nfsExport
  # defaults to "/", the NFSv4 pseudo-root path (an fsid=0 export -- see
  # hosts/thinkpad-simon's services.nfs.server.exports), not a real
  # filesystem path.
  #
  # The NFS *server* address is deliberately NOT a parameter here: it's
  # resolved at boot from a nixnetboot.nfs_server= kernel cmdline param
  # that nix-netboot-manager fills in per request (see its
  # routes/ipxe.rs), not baked into this build -- so the same artifact
  # keeps working if the manager's HOST_IP changes, and proper DHCP-issued
  # options aren't available (dnsmasq here runs in proxy-DHCP mode, so it
  # can't hand out e.g. a root-path option itself). See the
  # nfsroot-server-fixup generator below for how.
  netbootNfsrootModules =
    { nfsExport ? "/" }:
    [
      "${inputs.nixpkgs}/nixos/modules/installer/netboot/netboot.nix"

      (
        { lib, pkgs, ... }:
        {
          # Same disk/swap overrides as netbootModules above: this is a
          # stateless network boot, there's no local disk to touch.
          boot.loader.systemd-boot.enable = lib.mkForce false;
          boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
          boot.resumeDevice = lib.mkForce "";
          disko.devices = lib.mkForce { };
          swapDevices = lib.mkForce [ ];

          boot.initrd.supportedFilesystems = [
            "nfs"
            "nfsv4"
            "overlay"
          ];
          boot.initrd.availableKernelModules = [
            "nfs"
            "nfsv4"
            "overlay"
          ];

          # Overrides netboot.nix's own squashfs-loop definition of this
          # filesystem (set via mkImageMediaOverride) with an NFS mount of
          # the same read-only role in the overlay below it. The device is
          # a placeholder -- see nfsroot-server-fixup below, which patches
          # it with the real server address before systemd-fstab-generator
          # (which turns this fstab entry into the actual .mount unit) ever
          # reads it. Kept fully declarative (rather than hand-rolling the
          # mount as a bespoke service) specifically so NixOS's own
          # neededForBoot/depends/switch_root wiring for this filesystem --
          # validated by a real `nix build`, see the plan doc -- is
          # completely untouched; only the device *string* changes.
          fileSystems."/nix/.ro-store" = lib.mkForce {
            fsType = "nfs4";
            device = "NIXNETBOOT_NFS_SERVER_PLACEHOLDER:${nfsExport}";
            options = [ "ro" ];
            neededForBoot = true;
          };

          # Under systemd-stage-1 (confirmed active here via `nix eval` --
          # this nixpkgs pin defaults boot.initrd.systemd.enable to true),
          # `mount`'s nfs4 support comes from execing /sbin/mount.nfs4 on
          # PATH, which -- unlike the plain "mount"/"umount" util-linux
          # binaries systemd's own initrd.nix always includes -- is NOT
          # pulled in automatically. Legacy (non-systemd) stage-1 reportedly
          # doesn't need this (see xyno.space/posts/nix-store-nfs), but this
          # host's stage-1 is systemd-based, so it's added explicitly.
          boot.initrd.systemd.storePaths = [
            "${pkgs.nfs-utils}/bin/mount.nfs"
            "${pkgs.nfs-utils}/bin/mount.nfs4"
          ];

          # Patches the placeholder above with the real NFS server address
          # from /proc/cmdline's nixnetboot.nfs_server= param (set by
          # nix-netboot-manager per request), before
          # systemd-fstab-generator materializes the actual
          # /nix/.ro-store .mount unit from /etc/fstab.
          # /etc/systemd/system-generators is executed ahead of
          # /usr/lib/systemd/system-generators (where systemd's own
          # fstab-generator lives), per systemd.generator(7)'s documented
          # generator-directory search/execution order.
          #
          # UNLIKE the rest of this module, this specific ordering claim
          # could only be checked against systemd's docs, not proven by a
          # real `nix build` (evaluating/building can't exercise generator
          # *execution* order) -- test this via a real or QEMU boot before
          # trusting it on real hardware, same class of risk as the
          # flushBeforeStage2 gotcha above (silent hang, not a clean
          # error, if it's wrong).
          boot.initrd.systemd.contents."/etc/systemd/system-generators/nfsroot-server-fixup" = {
            mode = "0555";
            source = pkgs.writeShellScript "nfsroot-server-fixup" ''
              #!/bin/sh
              set -eu
              server=$(sed -n 's/.*nixnetboot\.nfs_server=\([^ ]*\).*/\1/p' /proc/cmdline)
              if [ -z "$server" ]; then
                echo "nfsroot-server-fixup: no nixnetboot.nfs_server= on /proc/cmdline" >&2
                exit 0
              fi
              sed -i "s|NIXNETBOOT_NFS_SERVER_PLACEHOLDER|$server|" /etc/fstab
            '';
          };

          boot.initrd.network.enable = true;
          boot.initrd.network.flushBeforeStage2 = false;
          # This host's common-desktop/NetworkManager module sets
          # networking.useDHCP = false at mkForce priority (NetworkManager
          # handles DHCP itself post-boot) -- override back to true so
          # stage-1 actually brings up an interface via DHCP before the NFS
          # mount above needs it. Harmless post-boot: NetworkManager takes
          # back over once the real system activates.
          networking.useDHCP = lib.mkForce true;
        }
      )
    ];

  # -------------------------
  # ISO modules
  # -------------------------
  isoModules = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

    (
      { pkgs, ... }:
      {
        services.openssh.enable = true;
        services.openssh.settings.PermitRootLogin = "yes";

        environment.systemPackages = with pkgs; [
          git
          vim
          wget
          curl
        ];

        isoImage.squashfsCompression = "zstd";
      }
    )
  ];

in
{
  # =========================================================
  # mkNixos
  # =========================================================
  mkNixos =
    {
      hostname,
      system,
      extraHmUsers ? { },
      extraModules ? [ ],
      enableComin ? true,
    }:

    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (homeManagerCfg system extraHmUsers)
        (commonModules system)
        (if enableComin then [ (cominModule hostname) ] else [ ])
        extraModules
      ];
    };

  # =========================================================
  # mkRaspberryPi
  # =========================================================
  mkRaspberryPi =
    {
      hostname,
      extraHmUsers ? { },
      extraModules ? [ ],
      enableComin ? true,
    }:

    inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      specialArgs = { inherit inputs; };

      modules = lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (homeManagerCfg "aarch64-linux" extraHmUsers)
        (commonModules "aarch64-linux")
        (if enableComin then [ (cominModule hostname) ] else [ ])
        rpiModules
        extraModules

        {
          nixpkgs.config.allowUnsupportedSystem = true;
          nixpkgs.hostPlatform.system = "aarch64-linux";
        }
      ];
    };

  # =========================================================
  # mkISO
  # =========================================================
  mkISO =
    {
      hostname,
      system,
      extraModules ? [ ],
      enableComin ? false,
    }:

    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (commonModules system)
        (if enableComin then [ (cominModule hostname) ] else [ ])
        isoModules
        extraModules
      ];
    };

  # =========================================================
  # mkNetboot
  # =========================================================
  mkNetboot =
    {
      hostname,
      system,
      extraModules ? [ ],
      enableComin ? false,
    }:

    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (homeManagerCfg system { })
        (commonModules system)
        (if enableComin then [ (cominModule hostname) ] else [ ])
        netbootModules
        extraModules
      ];
    };

  # =========================================================
  # mkNetbootNfsroot
  # =========================================================
  mkNetbootNfsroot =
    {
      hostname,
      system,
      nfsExport ? "/",
      extraHmUsers ? { },
      extraModules ? [ ],
      enableComin ? false,
    }:

    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs; };

      modules = lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (homeManagerCfg system extraHmUsers)
        (commonModules system)
        (if enableComin then [ (cominModule hostname) ] else [ ])
        (netbootNfsrootModules { inherit nfsExport; })
        extraModules
      ];
    };
}
