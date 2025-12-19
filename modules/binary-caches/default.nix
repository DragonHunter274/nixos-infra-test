{ config, lib, ... }:

{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      #      "https://attic.dh274.com/dragonhunter274"
      "https://hydra-cache.dh274.com"
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "dragonhunter274:YOJMbBYzAnReiYABcWPFDX0TYlQuO5R4W1jRgN2yN1k="
      "hydra-cache.dh274.com:L2u+qgjPh3/73whvVdEQt5qun5N4uU7dAa55Qulx9m0="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
