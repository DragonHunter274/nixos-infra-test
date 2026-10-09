{ config, pkgs, ... }:
{
  services.tailscale.enable = true;

  services.gradient = {
    enable = true;
    domain = "server-hetzner.taild08e19.ts.net";
    frontend.url = "https://server-hetzner.taild08e19.ts.net";
    packages.frontend = pkgs.gradient-frontend.overrideAttrs (old: {
      pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
        outputHash = "sha256-SP5vgJ9g776IRcj0cJS7WzWpoS3d++qNZ4VxylCTJck=";
      });
    });
    useTls = false;
    secrets.jwtFile = "/var/lib/gradient-secrets/jwt";
    secrets.cryptFile = "/var/lib/gradient-secrets/crypt";
    postgres.enable = true;
    worker.enable = true;
    githubApp = {
      enable = true;
      id = 5248499;
      privateKeyFile = "/run/secrets/gradient-github-app.pem";
      webhookSecretFile = "/run/secrets/gradient-github-app-webhook";
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
