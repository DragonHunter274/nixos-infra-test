{ ... }:
{
  # Advertise this machine as a Nix remote build machine on the local
  # network via mDNS, and accept builds over SSH from discoverers holding
  # the matching cluster private key (see thinkpad-simon's discover config).
  services.nix-builder-beacon = {
    advert = {
      enable = true;
      systems = [ "x86_64-linux" ];
      maxJobs = 10;  # add this
    };

    sshServe.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGirN2ebSLmUjaFR+uRTxz70vjT0oUpgRVl+ebbfDkTA nix-builder-beacon-cluster"
    ];
  };

  # Builds arrive over the restricted nix-ssh serve account, which isn't
  # trusted by default -- with require-sigs=true that makes every path
  # added during a build (e.g. FOD source fetches) get checked against
  # trusted-public-keys and rejected, since nothing here signs its own
  # store paths. Access to nix-ssh is already gated by the cluster key
  # above, so trust it the same way the beacon connection is trusted.
  nix.settings.trusted-users = [
    "root"
    "nix-ssh"
  ];

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
}
