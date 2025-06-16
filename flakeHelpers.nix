inputs:
let
  # Define mkMerge first since it's used by other functions
  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };

  homeManagerCfg =
    system: extraImports:
    { ... }:
    {
      home-manager.extraSpecialArgs = {
        pkgs-unstable = inputs.nixpkgs.legacyPackages.${system};
        pkgs-24-05 = inputs.nixpkgs-24-05.legacyPackages.${system};
        inherit inputs;
      };
      home-manager.users = extraImports;
    };

  commonModules = system: [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.comin.nixosModules.comin
    ./modules/usb-wakeup-disable.nix
    # Setup overlays
    (
      { pkgs, ... }:
      {
        nixpkgs.overlays = [
          (final: prev: { nur-packages = inputs.nur.packages.${system} or { }; })
          (final: prev: { unstable = inputs.nixpkgs.legacyPackages.${system}; })
          (final: prev: { pkgs-makemkv = inputs.makemkv.legacyPackages.${system} or prev.pkgs-makemkv; })
        ];
      }
    )
    # Setup home-manager
    inputs.home-manager.nixosModules.home-manager
    # Setup comin gitops
    (
      { ... }:
      {
        services.comin = {
          enable = true;
          allowForcePushMain = true;
          remotes = [
            {
              name = "origin";
              url = "https://github.com/fablabmuc-38c3/38c3-nixos.git";
              branches.main.name = "main";
            }
          ];
        };
      }
    )
  ];

  rpiModules = [
    # Import Raspberry Pi hardware module
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"

    # Basic Raspberry Pi configuration
    (
      { pkgs, lib, ... }:
      {
        # Basic hardware setup
        boot.loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };

        # Simple filesystem
        fileSystems."/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };

        # Enable SD image generation
        sdImage.compressImage = true;
      }
    )
  ];

  mkNixos = machineHostname: extraHmUsers: extraModules: {
    nixosConfigurations.${machineHostname} = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/${machineHostname}/configuration.nix
        (homeManagerCfg "x86_64-linux" extraHmUsers)
      ]
      ++ commonModules "x86_64-linux"
      ++ extraModules;
    };
  };

  mkRaspberryPi = machineHostname: extraHmUsers: extraModules: {
    nixosConfigurations.${machineHostname} = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = inputs.nixpkgs.lib.flatten [
        ./hosts/${machineHostname}/configuration.nix
        (homeManagerCfg "aarch64-linux" extraHmUsers)
        (commonModules "aarch64-linux")
        rpiModules
        extraModules
        [
          # Cross-compilation configuration
          (
            { pkgs, ... }:
            {
              # Enable QEMU emulation for building on x86_64
              nixpkgs.config.allowUnsupportedSystem = true;
              #nixpkgs.buildPlatform = "x86_64-linux";
              # Optimize for Raspberry Pi 4
              nixpkgs.hostPlatform = {
                system = "aarch64-linux";
                #      gcc.arch = "armv8-a+crc";
                #       gcc.cpu = "cortex-a72";
              };
            }
          )
        ]
      ];
    };
  };

  # Helper function to automatically generate hydraJobs from nixosConfigurations
  mkHydraJobs = nixosConfigurations: {
    # Build all NixOS system configurations
    nixos = inputs.nixpkgs.lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) nixosConfigurations;

    # Build SD images for Raspberry Pi systems
    sdImages = inputs.nixpkgs.lib.mapAttrs (_: cfg: cfg.config.system.build.sdImage) (
      inputs.nixpkgs.lib.filterAttrs (name: cfg: cfg.config.system.build ? sdImage) nixosConfigurations
    );

    # Build custom packages
    packages = {
      x86_64-linux = inputs.nur.packages.x86_64-linux or { };
      aarch64-linux = inputs.nur.packages.aarch64-linux or { };
    };
  };

  # Helper to create a complete flake with Hydra support
  mkFlakeWithHydra =
    configs:
    let
      baseFlake = mkMerge configs;
      hydraJobs = mkHydraJobs baseFlake.nixosConfigurations;
    in
    baseFlake
    // {
      inherit hydraJobs;

      # Add development shells
      devShells = {
        x86_64-linux.default = inputs.nixpkgs.legacyPackages.x86_64-linux.mkShell {
          buildInputs = with inputs.nixpkgs.legacyPackages.x86_64-linux; [
            nixos-rebuild
            nix-output-monitor
            nvd
            git
            nixfmt-rfc-style
            sops
          ];

          shellHook = ''
            echo "🚀 NixOS Infrastructure Development Environment"
            echo ""
            echo "Available hosts:"
            ${inputs.nixpkgs.lib.concatStringsSep "\n" (
              inputs.nixpkgs.lib.mapAttrsToList (name: _: "echo '  - ${name}'") baseFlake.nixosConfigurations
            )}
            echo ""
            echo "Commands:"
            echo "  nixos-rebuild switch --flake .#<hostname> --target-host <ip>"
            echo "  nix flake check"
            echo "  nix fmt"
            echo "  nix build .#hydraJobs.nixos.<hostname>"
            echo "  nix build .#hydraJobs.sdImages.<rpi-hostname>"
          '';
        };

        aarch64-linux.default = inputs.nixpkgs.legacyPackages.aarch64-linux.mkShell {
          buildInputs = with inputs.nixpkgs.legacyPackages.aarch64-linux; [
            nixos-rebuild
            git
            nixfmt-rfc-style
          ];
        };
      };
    };
in
{
  inherit
    mkMerge
    mkNixos
    mkRaspberryPi
    mkHydraJobs
    mkFlakeWithHydra
    ;
}
