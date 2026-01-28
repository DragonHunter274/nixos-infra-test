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
}
