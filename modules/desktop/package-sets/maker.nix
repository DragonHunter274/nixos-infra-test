{ pkgs, ... }:

with pkgs; [
  prusa-slicer
  orca-slicer
  kicad
  texliveFull
  texlivePackages.latexmk
]
