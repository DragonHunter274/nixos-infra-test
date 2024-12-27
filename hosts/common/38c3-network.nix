{ config, pkgs, ... }:

{
  networking.tempAddresses = "disabled";
  #networking.interfaces.enp1s0.acceptRA = true;
  networking.interfaces.enp43s0 = {
    ipv4.addresses = [{
        address = "151.217.62.81";
        prefixLength = 23;
      }];
  };
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles= {
    fiber = {
      connection = {
        id = "fiber";
        uuid = "5bc1572f-c4b3-36c4-8444-9a4c347158b2";
        type = "ethernet";
        autoconnect-priority = "-999";
        interface-name = "enp43s0";
        timestamp = "1735308281";
      };
      ipv6 = {
        addr-gen-mode = "0";
      };
    };
  };

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
