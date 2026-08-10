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
  # nfsServer IS a build-time parameter, baked statically into `device`
  # below -- a prior attempt made this dynamic (resolved at boot from a
  # kernel cmdline param) to avoid rebuilding if the manager's HOST_IP
  # changes, but that's not achievable under systemd-stage-1:
  # systemd-fstab-generator doesn't read /etc/fstab here at all, it reads
  # straight from $SYSTEMD_SYSROOT_FSTAB, a manager-level environment
  # variable baked into /etc/systemd/system.conf at build time and
  # pointing at an immutable /nix/store path -- nothing a runtime
  # generator does can redirect that. Making the server address genuinely
  # dynamic would mean hand-writing a custom mount unit replicating
  # NixOS's own neededForBoot/switch_root wiring instead of using
  # fileSystems at all; rebuilding on IP change is the accepted tradeoff
  # for now.
  netbootNfsrootModules =
    { nfsServer, nfsExport ? "/" }:
    [
      "${inputs.nixpkgs}/nixos/modules/installer/netboot/netboot.nix"

      (
        { lib, pkgs, config, ... }:
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

            # tothemoon's NIC is Realtek -- hardware-configuration.nix
            # deliberately doesn't list a NIC driver at all (a normal boot
            # only needs network in stage 2, not the initrd), which is why
            # stage-1 could never bring up ANY interface and hung forever
            # on "waiting for network to be online" regardless of the
            # anyInterface setting below -- there was nothing to wait on.
            # r8169 covers the RTL8111/8168/8169 Gigabit family (the
            # overwhelming majority of Realtek NICs on modern
            # motherboards); 8139cp/8139too are the older 10/100 Realtek
            # driver, included as a cheap safety net in case it's an older
            # board. NixOS's listOf module merging means this doesn't
            # clobber hardware-configuration.nix's own entries -- both
            # lists get concatenated.
            "r8169"
            "8139cp"
            "8139too"
          ];

          # Overrides netboot.nix's own squashfs-loop definition of this
          # filesystem (set via mkImageMediaOverride) with an NFS mount of
          # the same read-only role in the overlay below it.
          fileSystems."/nix/.ro-store" = lib.mkForce {
            fsType = "nfs4";
            device = "${nfsServer}:${nfsExport}";
            # vers=4.2 pinned explicitly to match what was actually tested
            # working (a manual `mount -t nfs4 -o ro,vers=4.2` against this
            # same export) -- avoids relying on whatever version this
            # constrained initrd environment would otherwise negotiate by
            # default.
            #
            # addr=${nfsServer}: mount.nfs4 normally derives this itself
            # by resolving the "server:" part of `device` via
            # getaddrinfo() -- confirmed failing here ("mount program did
            # not pass remote address") even with a real, valid IP as
            # device, so this isn't a DNS/hostname issue, it's
            # getaddrinfo() itself failing in this minimal initrd -- most
            # likely glibc's NSS modules (libnss_dns.so.2 etc.), which are
            # dlopen()'d at runtime per /etc/nsswitch.conf rather than
            # linked as a normal ELF dependency, so Nix's automatic
            # closure-copying for storePaths below never pulled them in.
            # Passing addr= explicitly (a literal value now, not a
            # placeholder -- nfsServer is static) sidesteps that
            # resolution step entirely.
            options = [
              "ro"
              "vers=4.2"
              "addr=${nfsServer}"
            ];
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
          # "Couldn't follow remote path" (a DIFFERENT nfs-utils error than
          # the two mount.nfs4-availability/addr= issues above, both
          # already fixed) suggests the NFSv4 pseudo-root walk itself is
          # failing during the mount handshake -- adding the ID-mapping
          # helpers (nfsidmap for the modern kernel request-key upcall
          # mechanism, rpc.idmapd for the older daemon-based one) as the
          # next candidate, since neither was present before and NFSv4
          # mount negotiation can depend on one of them being available.
          # sed is used by nix-path-registration-fixup's script below (and
          # was silently never available at runtime for the earlier,
          # since-reverted nfsroot-server-fixup generator too -- that was
          # only ever confirmed against build-time file content, never
          # actually exercised at boot). Not part of systemd stage-1's own
          # base storePaths (coreutils, but not gnused).
          boot.initrd.systemd.storePaths = [
            "${pkgs.nfs-utils}/bin/mount.nfs"
            "${pkgs.nfs-utils}/bin/mount.nfs4"
            "${pkgs.nfs-utils}/bin/nfsidmap"
            "${pkgs.nfs-utils}/bin/rpc.idmapd"
            "${pkgs.gnused}/bin/sed"
          ];

          boot.initrd.network.enable = true;
          boot.initrd.network.flushBeforeStage2 = false;
          # This host's common-desktop/NetworkManager module sets
          # networking.useDHCP = false at mkForce priority (NetworkManager
          # handles DHCP itself post-boot) -- override back to true so
          # stage-1 actually brings up an interface via DHCP before the NFS
          # mount above needs it. Harmless post-boot: NetworkManager takes
          # back over once the real system activates.
          networking.useDHCP = lib.mkForce true;
          boot.initrd.systemd.network.wait-online.anyInterface = true;

          # Debugging aid: without this, a failed mount drops to "emergency
          # mode" but root is locked ("Cannot open access to console, the
          # root account is locked") -- no way to actually see *why* it
          # failed (journalctl, /etc/fstab, /proc/cmdline) short of
          # photographing scrollback. Passwordless root on the local
          # console only (not exposed over network) -- acceptable for a
          # netboot image with no persistent state to protect anyway.
          boot.initrd.systemd.emergencyAccess = true;

          # Same debugging goal, but reachable remotely (copy-pasteable
          # output, not photos of scrollback) -- this is NixOS's normal
          # "remote-unlock encrypted disks over SSH" mechanism, repurposed
          # here since network is already up in this initrd anyway.
          # ignoreEmptyHostKeys: skips generating/baking in a persistent
          # host key, since this is a throwaway diagnostic tool on a
          # trusted LAN, not something worth TOFU/host-key pinning for.
          # PasswordAuthentication is hardcoded "no" in this module
          # (initrd-ssh.nix's own sshdConfig, before extraConfig gets
          # appended -- and sshd_config keeps the FIRST value seen per
          # directive, so extraConfig can't override it anyway) -- rather
          # than fight that, this is a throwaway ed25519 keypair generated
          # just for this debugging session, private half handed directly
          # to whoever's debugging, not simon's real key from
          # hosts/common/users.nix.
          boot.initrd.network.ssh = {
            enable = true;
            ignoreEmptyHostKeys = true;
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgK5rREVBaRrzVgzX5z94hkTFVQVLCVtGJNHFmR9Wzt nfsroot-debug-temp"
            ];
          };

          # initrd-ssh.nix's own systemd-stage-1 sshd.service is only
          # ordered `After=network.target` (networking subsystem exists,
          # says nothing about an interface actually being up) rather than
          # `After=network-online.target` (actual DHCP/connectivity) --
          # this is a real bug in that module for the systemd-stage-1 case,
          # not specific to our setup. `after`/`wants` are listOf and merge
          # across modules, so this ADDS network-online.target as an extra
          # ordering constraint on top of the module's own `after`, it
          # doesn't replace it.
          boot.initrd.systemd.services.sshd = {
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
          };

          # emergencyAccess/network.ssh above only cover the *initrd* --
          # once switch_root happens into the real (stateless, fresh
          # tmpfs-/etc-every-boot) system, those don't apply at all. Root
          # has no usable password there either: this host's config
          # manages secrets via sops-nix, which decrypts using the
          # persistent /etc/ssh/ssh_host_ed25519_key a real disk install
          # would have -- a netbooted system has no such persisted key, so
          # sops-nix secrets (root's password hash among them, if that's
          # how it's set here) silently never decrypt. Autologin on the
          # physical console sidesteps needing a password entirely, same
          # spirit as emergencyAccess for stage-1.
          services.getty.autologinUser = lib.mkForce "root";

          # netboot.nix's own boot.postBootCommands does
          # `nix-store --load-db < /nix/store/nix-path-registration` --
          # that file only ever exists because make-squashfs.nix injects
          # it directly into the squashfs blob it builds for
          # system.build.squashfsStore. We never build or use that
          # squashfs (the whole point of NFS-mounting /nix/store instead),
          # so that file was never going to exist on the real host store
          # ("No such file or directory" on that exact path, confirmed at
          # boot) -- and without the Nix database getting populated, later
          # nix-env/profile operations (home-manager activation, the
          # display manager setup) apparently fail/hang too.
          #
          # Two earlier attempts to fix this by referencing
          # config.system.build.toplevel from *inside* this module (once
          # directly in boot.postBootCommands, once via a separate
          # system.build.* option consumed by a stage-1 service) both hit
          # genuine infinite recursion -- toplevel's construction is
          # entangled with large parts of config (stage-2.nix's
          # postBootCommands embedding, and separately top-level.nix's
          # global `warnings` aggregation touching
          # boot.initrd.systemd.storePaths' automatic script-scanning) --
          # widely enough that no Nix-level reference to
          # config.system.build.toplevel from within boot.initrd.systemd.*
          # is safe in this nixpkgs version.
          #
          # Fix: the registration store path is computed OUTSIDE this
          # module entirely, at the flake-packaging level (see
          # parts/nfsroot-netboot.nix, where cfg.config is read as an
          # already-fully-resolved external value -- non-circular, same
          # reasoning as init=${toplevel}/init already being safe there),
          # and passed in as a plain runtime string via a
          # nixnetboot.registration= kernel cmdline param. This service's
          # script is pure shell parsing /proc/cmdline, with NO Nix-level
          # interpolation of anything toplevel-derived -- exactly the same
          # pattern as the (working, non-circular) NFS-server-address
          # cmdline parsing used earlier in this project's history.
          #
          # UNVERIFIED ordering, same caveat as flushBeforeStage2 earlier:
          # sysroot-nix-store.mount and initrd-switch-root.service are
          # systemd's own standard unit names (systemd.special(7)), not
          # NixOS-specific, but this exact sequencing could only be
          # checked against docs, not proven by a `nix build` -- test via
          # boot before trusting fully.
          boot.initrd.systemd.services.nix-path-registration-fixup = {
            description = "Copy the pre-computed Nix path registration into the writable store overlay";
            # network-online.target explicitly, not just inherited via
            # sysroot-nix-store.mount -- After= on a mount unit isn't the
            # same guarantee as the NFS connection underneath it actually
            # being settled (same gap already found and fixed for
            # sshd.service earlier in this module).
            after = [ "sysroot-nix-store.mount" "network-online.target" ];
            wants = [ "network-online.target" ];
            requisite = [ "sysroot-nix-store.mount" ];
            before = [ "initrd-switch-root.service" ];
            requiredBy = [ "initrd-switch-root.service" ];
            unitConfig.DefaultDependencies = false;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            # Full absolute paths for sed/cp, not bare names -- storePaths
            # above only makes their closures present in the store, it
            # does NOT put anything on $PATH (that's extraBin's job, for
            # the base initrd env only, not something a service picks up).
            # A bare `sed`/`cp` call here would rely on $PATH lookup
            # finding them, which was never going to work regardless of
            # storePaths ("sed missing" at runtime, confirmed at boot).
            script = ''
              set -eu
              registration=$(${pkgs.gnused}/bin/sed -n 's/.*nixnetboot\.registration=\([^ ]*\).*/\1/p' /proc/cmdline)
              if [ -z "$registration" ]; then
                echo "nix-path-registration-fixup: no nixnetboot.registration= on /proc/cmdline" >&2
                exit 0
              fi
              # Retry a few times -- the .ro-store NFS mount has already
              # shown transient failures once right after coming up (a
              # boot that failed, then succeeded on retry with no config
              # change), so a brief hiccup on the first read through it
              # right after mounting isn't implausible.
              for attempt in 1 2 3 4 5; do
                if ${pkgs.coreutils}/bin/cp "$registration" /sysroot/nix/store/nix-path-registration; then
                  exit 0
                fi
                echo "nix-path-registration-fixup: cp failed (attempt $attempt/5), retrying..." >&2
                ${pkgs.coreutils}/bin/sleep 2
              done
              exit 1
            '';
          };
        }
      )
    ];

  # -------------------------
  # ISO modules
  # -------------------------
  isoModules = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

    (
      { lib, pkgs, ... }:
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
        boot.loader.systemd-boot.enable = lib.mkForce false;
        boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
        boot.resumeDevice = lib.mkForce "";
        disko.devices = lib.mkForce { };
        swapDevices = lib.mkForce [ ];
        hardware.cpu.intel.updateMicrocode = lib.mkForce false;
        hardware.cpu.amd.updateMicrocode = lib.mkForce false;
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
        (homeManagerCfg system { })
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
      nfsServer,
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
        (netbootNfsrootModules { inherit nfsServer nfsExport; })
        extraModules
      ];
    };
}
