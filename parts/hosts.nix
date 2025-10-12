{ inputs, lib, ... }:
let
  # Import our helper functions
  builders = import ./lib.nix inputs;
  inherit (builders) mkNixos mkRaspberryPi mkISO;
in
{
  flake.nixosConfigurations = {
    # x86_64 hosts
    "fablabmuc-38c3" = mkNixos "fablabmuc-38c3" "x86_64-linux" { } [ ] { };
    "fablabmuc-38c3-minipc" = mkNixos "fablabmuc-38c3-minipc" "x86_64-linux" { } [ ] { };
    "desktop-simon" = mkNixos "desktop-simon" "x86_64-linux" { } [ ] { };
    "thinkpad-simon" = mkNixos "thinkpad-simon" "x86_64-linux" { } [
      inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
      inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
      ../modules/syncthing.nix
    ] { };
    "k3s-dev" = mkNixos "k3s-dev" "x86_64-linux" { } [ ../modules/k3s.nix ] { };

    # Raspberry Pi hosts
    "fablabmuc-tv" = mkRaspberryPi "fablabmuc-tv"
      { pi = import ../home/pi.nix; }
      [ ../modules/nmimport.nix ]
      { };

    # ISO installers
    "desktop-simon-iso" = mkISO "desktop-simon" "x86_64-linux" [ ] { };
    "thinkpad-simon-iso" = mkISO "thinkpad-simon" "x86_64-linux" [
      inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
      inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
      ../modules/syncthing.nix
    ] { };
  };
}
