{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  #  programs.hyprland.package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  #  programs.hyprland.portalPackage =
  #    inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;

  xdg = {
    portal = {
      enable = true;
      extraPortals = [
        #        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      xdgOpenUsePortal = false;
      config = {
        common = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
        };
      };
    };
  };

  environment.systemPackages = [
    pkgs.kitty
    pkgs.xdg-utils
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WL_RENDERER_ALLOW_SOFTWARE = "1";
}
