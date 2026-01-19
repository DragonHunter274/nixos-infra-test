{
  inputs,
  self,
  lib,
  ...
}:
{
  flake.hydraJobs = {
    # Build all NixOS system configurations (excluding ISO and netboot variants)
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel) (
      lib.filterAttrs (
        name: cfg: !(lib.hasSuffix "-iso" name) && !(lib.hasSuffix "-netboot" name)
      ) self.nixosConfigurations
    );

    # Build SD images for Raspberry Pi systems
    sdImages = lib.mapAttrs (_: cfg: cfg.config.system.build.sdImage) (
      lib.filterAttrs (name: cfg: cfg.config.system.build ? sdImage) self.nixosConfigurations
    );

    # ISO images are NOT included in the main hydraJobs to save storage
    # They are built in a separate Hydra jobset (main-isos) with keepnr=1
    # using the flakeref#isoImages syntax (requires patched Hydra)

    # Build netboot artifacts for netboot-enabled systems
    netboot = lib.mapAttrs (_: cfg: cfg.config.system.build.netboot) (
      lib.filterAttrs (name: cfg: cfg.config.system.build ? netboot) self.nixosConfigurations
    );

    # Build custom packages
    # wireshark is excluded from aarch64-linux to avoid unnecessary ARM builds
    # (it will still be built when used as a dependency in a system configuration)
    packages = {
      x86_64-linux = inputs.nur.packages.x86_64-linux or { };
      aarch64-linux = lib.filterAttrs (name: _: name != "wireshark") (
        inputs.nur.packages.aarch64-linux or { }
      );
    };
  };

  # Separate output for ISO images - NOT in hydraJobs to avoid building in main jobset
  # Built only in dedicated jobset using flakeref#isoImages with keepnr=1
  flake.isoImages = lib.mapAttrs (_: cfg: cfg.config.system.build.isoImage) (
    lib.filterAttrs (name: cfg: cfg.config.system.build ? isoImage) self.nixosConfigurations
  );
}
