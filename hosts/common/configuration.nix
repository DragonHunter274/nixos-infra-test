# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./users.nix
    ./38c3-network.nix
    ./zfs.nix
    ./disko-config.nix
    ./traefik.nix
    ./docker-compose/docker-compose.nix
    ./unbound.nix
    ./ftp_CCC.nix
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

  services.devmon.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;


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


  # Enable nginx service
  services.nginx = {
    enable = true;
    
    # Define virtual host for port 1234
    virtualHosts."localhost:1234" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = 1234;
        }
      ];
      
      # Serve the IP address information
      locations."/" = {
        extraConfig = ''
          # Set content type to plain text
          add_header Content-Type text/plain;
          
          # Execute ip a command and return output
          content_by_lua_block {
            local handle = io.popen("ip a")
            local result = handle:read("*a")
            handle:close()
            ngx.say(result)
          }
        '';
      };
    };
  };

  # Enable OpenResty (nginx with Lua support) instead of regular nginx
  # This is needed for the content_by_lua_block directive
  services.nginx.package = pkgs.openresty;

  # Open port 1234 in the firewall
  networking.firewall.allowedTCPPorts = [ 1234 ];

  # Alternative approach using a simple CGI script if you prefer not to use Lua
  # You can uncomment this section and comment out the Lua approach above
  /*
  services.nginx.virtualHosts."localhost:1234" = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 1234;
      }
    ];
    
    locations."/" = {
      extraConfig = ''
        # Create a simple script that outputs ip a
        root /var/www;
        try_files $uri @fallback;
      '';
    };
    
    locations."@fallback" = {
      extraConfig = ''
        internal;
        add_header Content-Type text/plain;
        return 200 "Use the Lua version above for dynamic IP output";
      '';
    };
  };
  
  # Create the directory and script
  system.activationScripts.create-ip-script = ''
    mkdir -p /var/www
    cat > /var/www/index.html << 'EOF'
    #!/bin/bash
    echo "Content-Type: text/plain"
    echo ""
    /run/current-system/sw/bin/ip a
    EOF
    chmod +x /var/www/index.html
  '';
  */




  systemd.services.ip-sender = {
    enable = true;
    description = "bar";
    unitConfig = {
      Type = "simple";
      # ...
    };
    serviceConfig = {
      ExecStart = "${inputs.nur.packages.x86_64-linux.ip-sender}/bin/arduino-ip-monitor";
      # ...
    };
    wantedBy = [ "multi-user.target" ];
    # ...
  };



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
    iproute2
    htop
    btop
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
