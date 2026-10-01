{ config, ... }:
{
  # Shared cluster key used to connect to beacon-discovered builders (e.g.
  # tothemoon). Its public half must be authorized in that builder's
  # services.nix-builder-beacon.sshServe.authorizedKeys.
  sops.secrets.nix_builder_beacon_key = {
    sopsFile = ../../secrets/secrets.yaml;
  };

  services.nix-builder-beacon.discover = {
    enable = true;
    # Don't let the beacon take sole ownership of nix.settings.builders --
    # it would otherwise drop the statically configured nix-arm-builder.
    # Both sources are merged below instead.
    addBuilder = false;
    sshKeyPath = config.sops.secrets.nix_builder_beacon_key.path;
  };

  # Merge the beacon's dynamically discovered LAN builders (tothemoon, when
  # online) with the statically configured nix-arm-builder (nix.buildMachines
  # -> /etc/nix/machines).
  nix.settings.builders = "@/etc/nix/machines ; @${config.services.nix-builder-beacon.discover.outputPath}";
}
