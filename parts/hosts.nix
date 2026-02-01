{
  inputs,
  ...
}:

let
  builders = import ./lib.nix inputs;
in
{
  flake.nixosConfigurations = {
    fablabmuc-38c3 = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "fablabmuc-38c3";
      extraHmUsers = { };
      extraModules = [ inputs.copyparty.nixosModules.default ];
    };

    fablabmuc-38c3-minipc = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "fablabmuc-38c3-minipc";
      extraHmUsers = { };
      extraModules = [ ];
    };

    desktop-simon = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "desktop-simon";
      extraHmUsers = { };
      extraModules = [ ];
    };

    thinkpad-simon = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "thinkpad-simon";
      extraHmUsers = { };
      extraModules = [
        inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
        inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
        ../modules/syncthing.nix
      ];
    };

    k3s-dev = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "k3s-dev";
      extraHmUsers = { };
      extraModules = [ ../modules/k3s.nix ];
    };

    k3s-dev-local = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "k3s-dev-local";
      extraHmUsers = { };
      extraModules = [ ../modules/k3s.nix ];
    };

    k3s-node2 = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "k3s-node2";
      extraHmUsers = { };
      extraModules = [ ../modules/k3s.nix ];
    };

    netboot-minimal-netboot = builders.mkNetboot {
      system = "x86_64-linux";
      hostname = "nixos-minimal";
    };

    netboot-minimal-iso = builders.mkISO {
      system = "x86_64-linux";
      hostname = "nixos-minimal";
    };

    hydra = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "hydra";
      extraHmUsers = { };
      extraModules = [ ];
    };

    fablabmuc-tv = builders.mkRaspberryPi {
      hostname = "fablabmuc-tv";
      extraHmUsers = {
        pi = import ../home/pi.nix;
      };
      extraModules = [ ../modules/nmimport.nix ];
    };
  };
}
