{ config, modulesPath, pkgs, lib, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
  ];

  networking.hostName = "hydra";

  nix.settings = {
    sandbox = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Automatic store optimization
  nix.optimise = {
    automatic = true;
    dates = [ "03:45" ]; # Run daily at 3:45 AM
  };

  proxmoxLXC = {
    manageNetwork = false;
    privileged = true;
  };

  security.pam.services.sshd.allowNullPassword = true;

  services.fstrim.enable = false; # Let Proxmox host handle fstrim

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PermitEmptyPasswords = "yes";
    };
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/secrets/cache-private-key.pem";
  };

  # Cache DNS lookups to improve performance
  services.resolved = {
    extraConfig = ''
      Cache=true
      CacheFromLocalhost=true
    '';
  };

  # Hydra CI/CD service
  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.dh274.com";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
  };

  # Open firewall for Hydra web interface
  networking.firewall.allowedTCPPorts = [ 3000 ];

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
  ];

  system.stateVersion = "25.05";
}
