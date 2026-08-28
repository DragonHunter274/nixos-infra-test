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
      extraModules = [ ../modules/k3s.nix ];
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
        inputs.nix-cache-beacon.nixosModules.default
        ../modules/syncthing.nix
      ];
    };

    t490s-simon = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "t490s-simon";
      extraHmUsers = { };
      extraModules = [
        inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.open-fprintd
        inputs.nixos-06cb-009a-fingerprint-sensor.nixosModules.python-validity
        ../modules/syncthing.nix
      ];
    };

    tothemoon = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "tothemoon";
      extraHmUsers = { };
      extraModules = [ ];
      nixpkgsInput = inputs.nixpkgs-26-05;
    };

    # NFS-store netboot variant of tothemoon ("windesktop" in
    # nix-netboot-manager): mounts /nix/store from thinkpad-simon's NFS
    # export instead of packing the whole desktop closure into the
    # client's RAM. nfsServer is baked in at build time -- see
    # netbootNfsrootModules in lib.nix for why a dynamic (DHCP-cmdline-
    # resolved) server address isn't achievable under systemd-stage-1;
    # re-run this build if thinkpad-simon's IP changes.
   # tothemoon-netboot-nfsroot = builders.mkNetbootNfsroot {
   #   system = "x86_64-linux";
   #   hostname = "tothemoon";
   #   nfsServer = "10.100.193.97";
   # };

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

    tothemars = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "tothemars";
      extraHmUsers = { };
      extraModules = [ ../modules/k3s.nix ];
    };

    k3s-node2 = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "k3s-node2";
      extraHmUsers = { };
      extraModules = [ ../modules/k3s.nix ];
    };
    
   nixos-minimal = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "nixos-minimal";
      extraHmUsers = { };
      extraModules = [ ];  
    };    

    netboot-minimal-netboot = builders.mkNetboot {
      system = "x86_64-linux";
      hostname = "nixos-minimal";
    };

    netboot-minimal-iso = builders.mkISO {
      system = "x86_64-linux";
      hostname = "nixos-minimal";
    };

    tothemoon-iso = builders.mkISO {
      system = "x86_64-linux";
      hostname = "tothemoon";
    };

    hydra = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "hydra";
      extraHmUsers = { };
      extraModules = [ ];
    };

    fablabmuc-vm = builders.mkNixos {
      system = "x86_64-linux";
      hostname = "fablabmuc-vm";
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
