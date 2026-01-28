{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    vim
    google-chrome
    swaynotificationcenter
    #jellyfin-media-player
    networkmanagerapplet
    signal-desktop
    thunderbird
    github-desktop
    prismlauncher
    moonlight-qt
    vesktop
    prusa-slicer
    orca-slicer
    usbutils
    pavucontrol
    gparted
    lunarvim
    kdePackages.krdc
    dnsutils
    ripgrep
    jq
    yq-go
    kubernetes-controller-tools
    neovim
    kicad
    roboto
    vscode-fhs
    inkscape
    # openscad-unstable
    element-desktop
    filezilla
    (python3.withPackages (
      ps: with ps; [
        pyserial
        pip
        kconfiglib
      ]
    ))
    segger-jlink-headless
    #cutecom
    nur-packages.rofi-nixsearch
    # nur-packages.mtkclient  # broken
    handbrake
    ffmpeg
    nur-packages.rbw-run
    rbw
  ];
}
