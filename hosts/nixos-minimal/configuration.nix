{
  pkgs,
  lib,
  ...
}:
{
  networking.hostName = "nixos-minimal";

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.MaxAuthTries = 10;

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.addresses = true;

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPjd9ez7/GjWl9sCkMzpyBONMoEnKG552aVqELOqf07R nixos-live"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "25.05";
}
