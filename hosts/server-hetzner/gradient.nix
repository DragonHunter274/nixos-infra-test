{ config, pkgs, inputs, ... }:
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;

    secrets = {
      gradient-jwt = { };
      gradient-crypt = { };
      gradient-github-app-key = { };
      gradient-github-app-webhook = { };
    };
  };

  services.tailscale.enable = true;

  services.gradient = {
    enable = true;
    domain = "server-hetzner.taild08e19.ts.net";
    frontend.url = "https://server-hetzner.taild08e19.ts.net";
    useTls = false;
    secrets.jwtFile = config.sops.secrets.gradient-jwt.path;
    secrets.cryptFile = config.sops.secrets.gradient-crypt.path;
    postgres.enable = true;
    worker.enable = true;
    githubApp = {
      enable = true;
      id = 5248499;
      privateKeyFile = config.sops.secrets.gradient-github-app-key.path;
      webhookSecretFile = config.sops.secrets.gradient-github-app-webhook.path;
    };
  };

  services.postgresql.package = pkgs.postgresql_18;

  systemd.services.gradient-funnel = {
    description = "Expose Gradient through Tailscale Funnel";
    wantedBy = [ "multi-user.target" ];
    requires = [
      "tailscaled.service"
      "gradient-server.service"
    ];
    after = [
      "tailscaled.service"
      "gradient-server.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.services.tailscale.package}/bin/tailscale funnel --bg --yes 80";
    };
  };
}
