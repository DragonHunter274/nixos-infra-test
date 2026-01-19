{
  config,
  modulesPath,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  hydraUser = config.users.users.hydra.name;
  hydraGroup = config.users.users.hydra.group;
  snix = import inputs.snix { localSystem = pkgs.stdenv.hostPlatform.system; };
in
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./hardware-configuration.nix
    inputs.sops-nix.nixosModules.sops
    # inputs.hydra-tools.nixosModules.hydra-github-bridge  # disabled - pulls in haskellNix/cabal
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

  # Configure Nix to use GitHub access token (avoid rate limiting)
  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-github-token.path}
  '';

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
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

  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
    PubkeyAcceptedKeyTypes ssh-ed25519
    ServerAliveInterval 60
    IPQoS throughput
    IdentityFile /root/.ssh/id_ed25519
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "localhost";
      system = "x86_64-linux";
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      maxJobs = 4; # Adjust based on your CPU cores
    }
    {
      hostName = "eu.nixbuild.net";
      system = "aarch64-linux";
      sshKey = "/var/lib/hydra/queue-runner/.ssh/id_ed25519";
      maxJobs = 100;
      supportedFeatures = [
        "benchmark"
        "big-parallel"
      ];
    }
  ];

  # Hydra CI/CD service
  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.dh274.com";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ "/etc/nix/machines" ];
    useSubstitutes = true;
    listenHost = "0.0.0.0";
    package = pkgs.hydra.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        ./flake-output-selection.patch
        ./disable-maintainer-notifications.patch
        ./ntfy-notification-plugin.patch
      ];
    });
    extraConfig = ''
      Include ${config.sops.secrets.hydra-gh-auth.path}
      max_unsupported_time = 30
      max_output_size = 10737418240
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
  networking.firewall.allowedTCPPorts = [
    3000
    5000
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
    snix.snix.cli.full-cli
    snix.snix.nar-bridge
    fuse3
  ];

  # Configure Hydra service users to have access to secrets
  users.users = {
    hydra-queue-runner.extraGroups = [ hydraGroup ];
    hydra-www.extraGroups = [ hydraGroup ];
  };

  # Hydra GitHub Bridge - reports build status to GitHub
  # Disabled - module pulls in haskellNix/cabal dependencies
  # services.hydra-github-bridge.default = {
  #   enable = false;
  #   ghAppId = 2507762;
  #   ghAppKeyFile = config.sops.secrets.github-app-key.path;
  #   ghUserAgent = "hydra-github-bridge/1.0 (hydra.dh274.com)";
  #   hydraHost = "https://hydra.dh274.com";
  #   hydraDb = "";
  # };

  # SOPS configuration
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile = "/root/.config/sops/age/keys.txt";

    secrets = {
      hydra-gh-auth = {
        owner = hydraUser;
        group = hydraGroup;
        mode = "0440";
      };
      nix-ssh-key = {
        owner = hydraUser;
        group = hydraGroup;
        mode = "0440";
      };
      nix-github-token = {
        owner = hydraUser;
        group = hydraGroup;
        mode = "0440";
      };
      github-app-key = {
        owner = hydraUser;
        group = hydraGroup;
        mode = "0440";
      };
    };
  };

  system.stateVersion = "25.05";
}
