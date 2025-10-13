{ config, modulesPath, pkgs, lib, inputs, ... }:
let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;
in
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "hydra";

  nix.settings = {
    sandbox = false;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    # Override substituters for Hydra - exclude local caches
    substituters = lib.mkForce [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = lib.mkForce [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
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
    listenHost = "0.0.0.0";
    package = pkgs.hydra_unstable.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        ./flake-output-selection.patch
      ];
    });
    extraConfig = ''
      Include ${config.sops.secrets.hydra-gh-auth.path}
      max_unsupported_time = 30
      <githubstatus>
        jobs = .*
        useShortContext = true
      </githubstatus>
    '';
    extraEnv = {
      HYDRA_DISALLOW_UNFREE = "0";
    };
  };

  # https://github.com/NixOS/nix/issues/4178#issuecomment-738886808
  systemd.services.hydra-evaluator.environment.GC_DONT_GC = "true";

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

  # Configure Hydra service users to have access to secrets
  users.users = {
    hydra-queue-runner.extraGroups = [ hydraGroup ];
    hydra-www.extraGroups = [ hydraGroup ];
  };

  # SOPS secrets for Hydra
  sops.secrets = {
    hydra-gh-auth = {
      sopsFile = ./secrets/secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0440";
    };
    nix-ssh-key = {
      sopsFile = ./secrets/secrets.yaml;
      owner = hydraUser;
      group = hydraGroup;
      mode = "0440";
    };
  };

  system.stateVersion = "25.05";
}
