{ config, lib, pkgs, inputs, ... }:
let
  pkgs-25-05 = import inputs."nixpkgs-25-05" { 
    system = pkgs.system; 
    config.allowUnfree = true;
  };
  
  cfg = config.services.goldwarden-legacy;
in
{
  options.services.goldwarden-legacy = {
    enable = lib.mkEnableOption "Goldwarden (legacy from nixpkgs-25.05)";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs-25-05.goldwarden;
      description = "The goldwarden package to use";
    };
    
    useSshAgent = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable Goldwarden's SSH Agent";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.useSshAgent -> !config.programs.ssh.startAgent;
      message = "Only one ssh-agent can be used at a time.";
    }];

    environment = {
      etc = lib.mkIf config.programs.chromium.enable {
        "chromium/native-messaging-hosts/com.8bit.bitwarden.json".source = "${cfg.package}/etc/chromium/native-messaging-hosts/com.8bit.bitwarden.json";
        "opt/chrome/native-messaging-hosts/com.8bit.bitwarden.json".source = "${cfg.package}/etc/chrome/native-messaging-hosts/com.8bit.bitwarden.json";
      };

      sessionVariables = lib.mkIf cfg.useSshAgent {
        SSH_AUTH_SOCK = "$HOME/.goldwarden-ssh-agent.sock";
      };

      systemPackages = [
        cfg.package
        config.programs.gnupg.agent.pinentryPackage
      ];
    };

    programs.firefox.nativeMessagingHosts.packages = [ cfg.package ];

    systemd.user.services.goldwarden = {
      description = "Goldwarden daemon (legacy)";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${lib.getExe cfg.package} daemonize";
      path = [ config.programs.gnupg.agent.pinentryPackage ];
      unitConfig.ConditionUser = "!@system";
    };
  };
}
