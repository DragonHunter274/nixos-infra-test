{ config, pkgs, ... }:

{
  networking.tempAddresses = "disabled";
  #networking.interfaces.enp1s0.acceptRA = true;
#  networking.interfaces.enp43s0 = {
#    ipv4.addresses = [
#      {
#        address = "151.217.62.81";
#        prefixLength = 23;
#      }
#    ];
#  };
  networking.networkmanager = {
    settings.connection."ipv6.addr-gen-mode" = "eui64";
    settings.connection."ipv6.ip6-privacy" = "0";
  };
  services.tailscale.enable = true;

#  networking.defaultGateway.interface = "enp43s0";
#  networking.defaultGateway.address = "151.217.62.1";

  services.lldpd.enable = true;

  services.lldpd.extraArgs = [
    "-S"
    "Assembly: Fabulous Lab Munich - contact: admin@dh274.com - description: Server in Club Mate Crate"
  ];
  networking.firewall.allowedUDPPorts = [ 646 ]; # Port used for LLDP

  # Firewall
  networking.firewall = {
    enable = true;

    pingLimit = "--limit 1/minute --limit-burst 5";

    # Allow HTTP and HTTPS on all interfaces
    allowedTCPPorts = [
      80
      443
    ];

  # Allow FTP and ssh on enp43s0
    allowedTCPPorts = [ 21 ];  # FTP control port
    allowedTCPPortRanges = [
      { from = 21100; to = 21110; }  # Passive mode data ports
    ];

    interfaces.tailscale0 = {
      allowedTCPPorts = [ 22 ];
    };

  };
}
