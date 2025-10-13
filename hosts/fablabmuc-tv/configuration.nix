# hosts/rpi-example/configuration.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{

  imports = [ ./hyprland.nix ];

  # Filter out non-existent kernel modules from SD image initrd
  boot.initrd.includeDefaultModules = lib.mkForce false;
  boot.initrd.availableKernelModules = lib.mkForce [
    # Core storage drivers
    "ext2" "ext4" "ahci" "nvme" "uas" "usb_storage" "sd_mod" "sdhci_pci"
    # USB and HID
    "usbhid" "hid_generic" "hid_apple" "hid_cherry" "hid_corsair"
    "hid_lenovo" "hid_logitech_dj" "hid_logitech_hidpp" "hid_microsoft" "hid_roccat"
    # USB host controllers
    "ehci_hcd" "ehci_pci" "ohci_hcd" "ohci_pci" "uhci_hcd" "xhci_hcd" "xhci_pci"
    # MMC for Raspberry Pi SD card
    "mmc_block"
    # Virtio (useful for virtualization during build)
    "virtio_balloon" "virtio_blk" "virtio_console" "virtio_mmio" "virtio_net" "virtio_pci" "virtio_scsi"
    # VC4 GPU driver for Raspberry Pi
    "vc4"
  ];
  # System configuration

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };

  #  hardware.deviceTree = {
  #    enable = true;
  #    filter = lib.mkForce "bcm2711-rpi-4-b.dtb";
  #    overlays = [
  #      "${pkgs.linuxKernel.kernels.linux_rpi4}/dtbs/overlays/tc358743.dtbo"
  #    ];
  #  };

  nixpkgs.overlays = [
    # Fix libraspberrypi for CMake 4.0 compatibility
    (self: super: {
      libraspberrypi = super.libraspberrypi.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or []) ++ [
          ./patches/libraspberrypi-cmake-v4.patch
        ];
      });
      libcec = super.libcec.override { withLibraspberrypi = true; };
    })
  ];

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    raspberry-pi."4".tc358743.enable = true;
    deviceTree = {
      enable = true;
    };
  };

  services.udev.extraRules = ''
    # allow access to raspi cec device for video group (and optionally register it as a systemd device, used below)
    KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';

  environment.variables = {
    QML2_IMPORT_PATH =
      let
        qtModules = with pkgs.qt6; [
          qtwebsockets
          # Add more here
        ];
      in
      builtins.concatStringsSep ":" (map (pkg: "${pkg}/${pkgs.qt6.qtbase.qtQmlPrefix}") qtModules);
  };

  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "pi"; # Replace with your actual username
  };

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

  services.displayManager.sddm.wayland.enable = true;

  system.stateVersion = "24.05";

  # Hostname
  networking.hostName = "fablabmuc-tv";

  networking.networkmanager.enable = true;

  # Enable the boot import feature
  services.networkmanager.bootImport = {
    enable = true;
    # Optional: customize these settings
    # bootPath = "/boot";  # Default location
    # removeAfterImport = true;  # Remove files after importing
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    extraConfig = ''
      MaxAuthTries 20
    '';
  };
hardware.raspberry-pi."4".fkms-3d.enable = true;
  # User configuration
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPIPn/hG5HBmP/tTElEiBVKADNze2QOljhbbzNXnGV2 fablabmuc-tv"
    ];
  };

  # Enable sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Console configuration
  console.enable = false;

  # Reduce journal size to save SD card space
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxRetentionSec=7day
  '';

  programs.hyprland.enable = true;

  # Basic system packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
    unzip
    rsync
    kitty
    feh
    firefox
    ffmpeg
    libcec
    quickshell
    qt6.qtwebsockets
    qt6.qtdeclarative
    qt6.qtbase
  ];

  # Enable Nix flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize nix store
  nix.settings.auto-optimise-store = true;

  # Reduce swapping to preserve SD card
  boot.kernel.sysctl = {
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };

  # Mount tmpfs for temporary files
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "nodev"
      "nosuid"
      "size=1G"
    ];
  };
}
