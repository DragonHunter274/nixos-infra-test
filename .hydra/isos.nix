# Legacy Hydra jobset file for ISO images only
# This allows us to have a separate jobset with keepnr=1 to save storage
# ISO images are NOT in the main hydraJobs output to avoid building them twice
{ nixexpr }:
let
  flake = builtins.getFlake (toString nixexpr + "/.");
in
flake.outputs.isoImages or {}
