{ inputs, lib, ... }:

{
  perSystem =
    {
      system,
      ...
    }:
    let
      builders = import ./lib.nix inputs;

      # Only build ISOs for x86_64-linux
      isoConfigs = lib.optionalAttrs (system == "x86_64-linux") {
        "iso-desktop-simon" =
          (builders.mkISO {
            inherit system;
            hostname = "desktop-simon";
            extraModules = [ ];
          }).config.system.build.isoImage;

        "iso-thinkpad-simon" =
          (builders.mkISO {
            inherit system;
            hostname = "thinkpad-simon";
            extraModules = [
              inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
              inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
              ../modules/syncthing.nix
            ];
          }).config.system.build.isoImage;
      };
    in
    {
      packages = isoConfigs;
    };
}
