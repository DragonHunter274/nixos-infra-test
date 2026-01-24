{ pkgs, inputs, ... }:

{
  # Desktop system packages
  # These packages are installed system-wide and available to all users
  environment.systemPackages = with pkgs; [
    cachix
    (python3.withPackages (
      ps: with ps; [
        pyserial
        kconfiglib
      ]
    ))
    nixfmt-rfc-style
    tlp
    bitwarden-desktop
    kdePackages.qtsvg
    inputs.pyprland.packages."x86_64-linux".pyprland
    elegant-sddm
    xdg-utils
    android-tools
    go
    tinygo
    gcc
    stlink
    openocd
    #adafruit-nrfutil
    distrobox
    # (limesuite.override { withGui = true; })
    nfs-utils
    nodejs_24
    pico-sdk
    # nur-packages.openbeken-flasher
    # nur-packages.mtkclient
    #  wget
    icu
    icu.dev
    sops
    # jetbrains.clion # TODO: broken build - jetbrains-jdk-jcef fails to build from source
    claude-code
    zed-editor-fhs
    nixd
    nil
    kubectl
  ];
}
