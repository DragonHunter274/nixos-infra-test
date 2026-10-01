{ ... }:
{
  # Advertise this machine as a Nix remote build machine on the local
  # network via mDNS, and accept builds over SSH from discoverers holding
  # the matching cluster private key (see thinkpad-simon's discover config).
  services.nix-builder-beacon = {
    advert = {
      enable = true;
      systems = [ "x86_64-linux" ];
    };

    sshServe.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGirN2ebSLmUjaFR+uRTxz70vjT0oUpgRVl+ebbfDkTA nix-builder-beacon-cluster"
    ];
  };

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
}
