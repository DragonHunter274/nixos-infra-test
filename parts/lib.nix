inputs:
let
  # Common modules for all hosts
  commonModules = system: [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.comin.nixosModules.comin
    ../modules/usb-wakeup-disable.nix
    
    # Overlays module
    ({ pkgs, ... }: {
      nixpkgs.overlays = [
        (final: prev: { nur-packages = inputs.nur.packages.${system} or { }; })
        (final: prev: { unstable = inputs.nixpkgs.legacyPackages.${system}; })
        (final: prev: { pkgs-makemkv = inputs.makemkv.legacyPackages.${system} or prev.pkgs-makemkv; })
      ];
    })
    
    # Home-manager setup
    inputs.home-manager.nixosModules.home-manager
    
    # Comin gitops
    ({ ... }: {
      services.comin = {
        enable = true;
        allowForcePushMain = true;
        remotes = [{
          name = "origin";
          url = "https://github.com/dragonhunter274/nixos-infra-test.git";
          branches.main.name = "main";
        }];
      };
    })
  ];

  # Home-manager configuration helper
  homeManagerCfg = system: extraImports: { ... }: {
    home-manager.extraSpecialArgs = {
      pkgs-unstable = inputs.nixpkgs.legacyPackages.${system};
      pkgs-24-05 = inputs.nixpkgs-24-05.legacyPackages.${system};
      inherit inputs;
    };
    home-manager.users = extraImports;
  };

  # Raspberry Pi specific modules
  rpiModules = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ({ pkgs, lib, ... }: {
      boot.loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
      fileSystems."/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
      sdImage.compressImage = true;
    })
  ];

  # ISO image modules
  isoModules = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ({ pkgs, lib, ... }: {
      # Enable SSH in the installer
      services.openssh.enable = true;
      
      # Allow password login for installation
      services.openssh.settings.PermitRootLogin = "yes";
      
      # Set a default password (you should change this!)
      # users.users.root.initialPassword = "nixos";
      
      # Optional: Include additional tools in the ISO
      environment.systemPackages = with pkgs; [
        git
        vim
        wget
        curl
      ];
      
      # Compress the ISO
      isoImage.squashfsCompression = "zstd";
    })
  ];
in
{
  # Helper to create a NixOS system
  mkNixos = hostname: system: extraHmUsers: extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = inputs.nixpkgs.lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (homeManagerCfg system extraHmUsers)
        (commonModules system)
        extraModules
      ];
    };

  # Helper to create a Raspberry Pi system
  mkRaspberryPi = hostname: extraHmUsers: extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs; };
      modules = inputs.nixpkgs.lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (homeManagerCfg "aarch64-linux" extraHmUsers)
        (commonModules "aarch64-linux")
        rpiModules
        extraModules
        [
          ({ pkgs, ... }: {
            nixpkgs.config.allowUnsupportedSystem = true;
            nixpkgs.hostPlatform = {
              system = "aarch64-linux";
            };
          })
        ]
      ];
    };

  # Helper to create an ISO installer system
  mkISO = hostname: system: extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = inputs.nixpkgs.lib.flatten [
        ../hosts/${hostname}/configuration.nix
        (commonModules system)
        isoModules
        extraModules
      ];
    };
}
