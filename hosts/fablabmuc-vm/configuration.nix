{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # Specify the disk device for disko partitioning
  # KVM guest with virtio-blk bus -> /dev/vda. Adjust if the VM instead uses
  # virtio-scsi (/dev/sda) or emulated NVMe (/dev/nvme0n1).
  disko.devices.disk.main.device = "/dev/sda";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    tmux
    openssh
    util-linux
  ];

  networking.hostName = "fablabmuc-vm";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "prohibit-password";

  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMrUsj8WPgNzTTEbt2/QXsEaJs/K9SuTbrqdgk0xSRC simon@thinkpad-simon"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII5ysOCCkd6Me7t/Gx3CxLQ0tCfte3/gI1yXIWASG3Cc abc@webtop-689b4b4bb4-j9wnn"
  ];
  services.printing.drivers = [
    pkgs.hplip
    pkgs.nur-packages.tsc-printer
    pkgs.samsung-unified-linux-driver
    (pkgs.writeTextDir "share/cups/model/brother_ql570_printer_en.ppd" (
      builtins.readFile ./brother_ql570_printer_en.ppd
    ))
  ];

  systemd.services.cups-tsc-printer-setup = {
    description = "Add TSC ME240 printer queue";
    wantedBy = [ "multi-user.target" ];
    after = [ "cups.service" ];
    requires = [ "cups.service" ];
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    script = ''
      # Wait for CUPS socket to be ready
      for i in $(seq 1 10); do
        ${pkgs.cups}/bin/lpstat -H && break
        echo "Waiting for CUPS... ($i)"
        sleep 1
      done

      if ! ${pkgs.cups}/bin/lpstat -p TSC-ME240 2>/dev/null | grep -q TSC-ME240; then
        ${pkgs.cups}/bin/lpadmin \
          -p TSC-ME240 \
          -v socket://10.100.163.75:9100 \
          -P ${pkgs.nur-packages.tsc-printer}/share/cups/model/tsc-ppds/ME240.ppd \
          -E
        ${pkgs.cups}/bin/lpadmin -d TSC-ME240
      fi

      if ! ${pkgs.cups}/bin/lpstat -p TSC-ME240-raw 2>/dev/null | grep -q TSC-ME240-raw; then
        ${pkgs.cups}/bin/lpadmin \
          -p TSC-ME240-raw \
          -v socket://10.100.163.75:9100 \
          -m raw \
          -E
      fi
    '';
  };
  nix.settings = {
    trusted-users = [ "root" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = "auto";
    cores = 0; # Use all available cores
  };

  system.stateVersion = "25.05";
}
