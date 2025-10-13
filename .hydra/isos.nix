# Legacy Hydra jobset file for ISO images only
# This allows us to have a separate jobset with keepnr=1 to save storage
# ISO images are NOT in the main hydraJobs output to avoid building them twice
{ nixexpr }:
let
  lock = builtins.fromJSON (builtins.readFile (nixexpr + "/flake.lock"));

  flake-compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/master.tar.gz";
    sha256 = "0m9grvfsbwmvgwaxvdzv6cmyvjnlww004gfxjvcl806ndqaxzy4j";
  };

  flake = (import flake-compat { src = nixexpr; }).defaultNix;
in
flake.isoImages or {}
