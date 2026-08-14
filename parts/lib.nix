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
          (final: prev: {
            age-plugin-tpm-legacy = prev.age-plugin-tpm.overrideAttrs (old: {
              version = "0.3.0";
              src = prev.fetchFromGitHub {
                owner = "Foxboron";
                repo = "age-plugin-tpm";
                rev = "v0.3.0";
                hash = "sha256-yr1PSSmcUoOrQ8VMQEoaCLNvDO+3+6N7XXdNUyYVz9M=";
              };
              vendorHash = "sha256-VEx6qP02QcwETOQUkMsrqVb+cOElceXcTDaUr480ngs=";
              # v0.3.0 predates the --version flag added for the 1.0.1 release.
              doInstallCheck = false;
              doCheck = false;
            });
          })
          (final: prev: {
            spotify-x11 = prev.symlinkJoin {
              name = "spotify-x11-${prev.spotify.version}";
              paths = [ prev.spotify ];
              nativeBuildInputs = [ prev.makeWrapper ];
              postBuild = ''
                rm "$out/bin/spotify"
                makeWrapper "${prev.spotify}/share/spotify/spotify" "$out/bin/spotify" \
                  --unset NIXOS_OZONE_WL
              '';
            };
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
            "r8169"
            "8139cp"
            "8139too"
          ];


          fileSystems."/nix/.ro-store" = lib.mkForce {
            fsType = "nfs4";
            device = "${nfsServer}:${nfsExport}";
            options = [
              "ro"
              "vers=4.2"
              "addr=${nfsServer}"
            ];
            neededForBoot = true;
          };


          boot.initrd.systemd.storePaths = [
            "${pkgs.nfs-utils}/bin/mount.nfs"
            "${pkgs.nfs-utils}/bin/mount.nfs4"
            "${pkgs.nfs-utils}/bin/nfsidmap"
            "${pkgs.nfs-utils}/bin/rpc.idmapd"
            "${pkgs.gnused}/bin/sed"
          ];

          boot.initrd.network.enable = true;
          boot.initrd.network.flushBeforeStage2 = false;
          networking.useDHCP = lib.mkForce true;
          boot.initrd.systemd.network.wait-online.anyInterface = true;

          boot.initrd.systemd.emergencyAccess = true;
          boot.initrd.network.ssh = {
            enable = true;
            ignoreEmptyHostKeys = true;
            authorizedKeys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgK5rREVBaRrzVgzX5z94hkTFVQVLCVtGJNHFmR9Wzt nfsroot-debug-temp"
            ];
          };

          boot.initrd.systemd.services.sshd = {
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
          };


          services.getty.autologinUser = lib.mkForce "root";
          boot.initrd.systemd.services.nix-path-registration-fixup = {
            description = "Copy the pre-computed Nix path registration into the writable store overlay";
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
