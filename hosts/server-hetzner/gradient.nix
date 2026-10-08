{ config, pkgs, ... }:
{
  services.tailscale.enable = true;

  services.gradient = {
    enable = true;
    domain = "server-hetzner.taild08e19.ts.net";
    serveUrl = "https://server-hetzner.taild08e19.ts.net";
    useTls = false;
    secrets.jwtFile = "/var/lib/gradient-secrets/jwt";
    secrets.cryptFile = "/var/lib/gradient-secrets/crypt";
    postgres.enable = true;
    worker.enable = true;
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
      ExecStart = "${config.services.tailscale.package}/bin/tailscale funnel --bg --yes 3000";
    };
  };
}
