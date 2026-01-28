# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./users.nix
    ./38c3-network.nix
    ./zfs.nix
    ./disko-config.nix
    ./traefik.nix
    ./docker-compose.nix
    ./unbound.nix
    # ./sops_fetch.nix
  ];
  nix.settings.trusted-users = [ "@wheel" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true; # for IPv4
    nssmdns6 = true; # for IPv6 if you need it
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    openFirewall = true; # This handles the firewall rules automatically
  };

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # Enable networking
  networking.networkmanager.enable = true;
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # ip-sender service (incomplete - needs configuration)
  # systemd.services.ip-sender = {
  #   enable = true;
  #   description = "bar";
  #   unitConfig = {
  #     Type = "simple";
  #     # ...
  #   };
  #   serviceConfig = {
  #     ExecStart = "${inputs.nur.packages.x86_64-linux.ip-sender}/bin/ip-sender";
  #     # ...
  #   };
  #   wantedBy = [ "multi-user.target" ];
  #   # ...
  # };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs = {
    zsh = {
      enable = true;
      ohMyZsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = [
          "sudo"
          "terraform"
          "systemadmin"
          "git"
          "kubectl"
        ];
      };
    };
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
    sops
    nixfmt-rfc-style
    git
    kitty
    pciutils
    compose2nix
    tmux
    zenith
  ];

  security.sudo.wheelNeedsPassword = false;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
