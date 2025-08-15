{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:

{

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services.flatpak.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  hardware.rtl-sdr.enable = true;
  users.users.simon.extraGroups = [ "plugdev" ];

  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/simon/.config/sops/age/keys.txt";

  sops.secrets.example_key = { };
  sops.secrets."myservice/my_subdir/my_secret" = { };

  systemd.services."sometestservice" = {
    script = ''
      echo "
      Hey bro! I'm a service, and imma send this secure password:
      $(cat ${config.sops.secrets."myservice/my_subdir/my_secret".path})
      located in:
      ${config.sops.secrets."myservice/my_subdir/my_secret".path}
      to database and hack the mainframe
      " > /var/lib/sometestservice/testfile
    '';
    serviceConfig = {
      User = "sometestservice";
      WorkingDirectory = "/var/lib/sometestservice";
      Type = "oneshot";
    };
  };

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

  time.timeZone = "Europe/Berlin";
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  environment.etc."docker/config.json".text = builtins.toJSON {
    credsHelpers = {
      "ghcr.io" = "ghcr-login";
    };
  };

  programs.yazi = {
    enable = true;
  };

  programs.wireshark.enable = true;

  environment.systemPackages = with pkgs; [
    #nur-packages.docker-credential-ghcr-login
    gh
    wireshark
    gnumake
    btop
  ];
}
