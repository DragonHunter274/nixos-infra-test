# Legacy Hydra jobset file for ISO images only
# This allows us to have a separate jobset with keepnr=1 to save storage
# ISO images are NOT in the main hydraJobs output to avoid building them twice
{ nixexpr, flake-compat }:
let
  flake = (import flake-compat { src = nixexpr; }).defaultNix;
in
flake.isoImages or {}
