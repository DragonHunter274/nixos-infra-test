inputs:
let
  homeManagerCfg = extraImports: {
    home-manager.extraSpecialArgs = {
      pkgs-unstable = inputs.nixpkgs.legacyPackages.x86_64-linux;
      pkgs-24-05 = inputs.nixpkgs-24-05.legacyPackages.x86_64-linux;
      inherit inputs;
    };
    home-manager.users = extraImports;
  };

  commonModules = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.comin.nixosModules.comin
    ./modules/usb-wakeup-disable.nix
    # Setup overlays
    (
      { pkgs, ... }:
      {
        nixpkgs.overlays = [
          (final: prev: { nur-packages = inputs.nur.packages.x86_64-linux; })
          (final: prev: { unstable = inputs.nixpkgs.legacyPackages.x86_64-linux; })
          (final: prev: { pkgs-makemkv = inputs.makemkv.legacyPackages.x86_64-linux; })
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
              url = "https://github.com/dragonhunter274/nixos-infra-test.git";
              branches.main.name = "main";
            }
          ];
        };
      }
    )
  ];
in
{
  mkNixos = machineHostname: extraHmUsers: extraModules: {
    nixosConfigurations.${machineHostname} = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/${machineHostname}/configuration.nix
        (homeManagerCfg extraHmUsers)
      ]
      ++ commonModules
      ++ extraModules;
    };
  };

  mkMerge = inputs.nixpkgs.lib.lists.foldl' (
    a: b: inputs.nixpkgs.lib.attrsets.recursiveUpdate a b
  ) { };
}
