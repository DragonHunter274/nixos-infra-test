{ inputs, self, lib, ... }:
{
  flake.hydraJobs = {
    # Build all NixOS system configurations (excluding ISO and netboot variants)
    nixos = lib.mapAttrs
      (_: cfg: cfg.config.system.build.toplevel)
      (lib.filterAttrs
        (name: cfg:
          !(lib.hasSuffix "-iso" name) &&
          !(lib.hasSuffix "-netboot" name)
        )
        self.nixosConfigurations);

    # Build SD images for Raspberry Pi systems
    sdImages = lib.mapAttrs 
      (_: cfg: cfg.config.system.build.sdImage)
      (lib.filterAttrs 
        (name: cfg: cfg.config.system.build ? sdImage) 
        self.nixosConfigurations);

    # Build ISO images for installer systems
    isoImages = lib.mapAttrs 
      (_: cfg: cfg.config.system.build.isoImage)
      (lib.filterAttrs 
        (name: cfg: cfg.config.system.build ? isoImage) 
        self.nixosConfigurations);

    # Build netboot artifacts for netboot-enabled systems
    netboot = lib.mapAttrs 
      (_: cfg: cfg.config.system.build.netboot)
      (lib.filterAttrs 
        (name: cfg: cfg.config.system.build ? netboot) 
        self.nixosConfigurations);

    # Build custom packages
    packages = {
      x86_64-linux = inputs.nur.packages.x86_64-linux or { };
      aarch64-linux = inputs.nur.packages.aarch64-linux or { };
    };
  };
}
