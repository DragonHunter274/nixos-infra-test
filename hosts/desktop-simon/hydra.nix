{ config, pkgs, ... }:

{
  services.hydra-dev = {
    enable = true;
    hydraURL = "https://hydra.dh274.com";
    notificationSender = "hydra@your-domain.com";
    # Enable webhook support
    extraConfig = ''
      max_concurrent_evals = 4
      base_uri = https://hydra.dh274.com
    '';
  };
}
