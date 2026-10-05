{
  config,
  pkgs,
  lib,
  ...
}:

{

  options.security.sops-tpm = lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable TPM support for SOPS.";
        };

      };
    };
    default = { };
  };
  config = lib.mkIf config.security.sops-tpm.enable {
    environment.systemPackages = [ pkgs.age-plugin-tpm ];
    sops.age.keyFile = "/etc/sops-nix/tpm-identity.txt";
    sops.age.plugins = [ pkgs.age-plugin-tpm-legacy ];
    system.activationScripts.setupTpmForSopsNix.text = ''
      mkdir -p /etc/sops-nix
      ${pkgs.tpm2-tools}/bin/tpm2_nvread 0x1500016 -C o -o /etc/sops-nix/tpm-identity.txt
    '';
    system.activationScripts.setupSecrets.deps = [ "setupTpmForSopsNix" ];
  };
}
