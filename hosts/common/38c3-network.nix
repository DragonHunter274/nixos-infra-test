{ config, pkgs, ... }:

{
  networking.tempAddresses = "disabled";
  #networking.interfaces.enp1s0.acceptRA = true;
  #networking.interfaces.enp43s0 = {
  #  ipv4.addresses = [{
  #      address = "151.217.62.81";
  #      prefixLength = 23;
  #    }];
  #};
  networking.networkmanager = {
    settings.connection."ipv6.addr-gen-mode" = "eui64";
    settings.connection."ipv6.ip6-privacy" = "0";
  };
  services.tailscale.enable = true;


  services.lldpd.enable = true;

  services.lldpd.extraArgs = [
    "-S"
    "Assembly: Fabulous Lab Munich - contact: admin@dh274.com - description: Server in Club Mate Crate"
  ];
  networking.firewall.allowedUDPPorts = [ 646 ]; # Port used for LLDP

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
}
