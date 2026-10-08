{ config, pkgs, ... }:
{
  services.tailscale.enable = true;

  services.gradient = {
    enable = true;
    domain = "server-hetzner.taild08e19.ts.net";
    frontend.url = "https://server-hetzner.taild08e19.ts.net";
    packages.frontend = pkgs.gradient-frontend.overrideAttrs (old: {
      pnpmDeps = old.pnpmDeps.overrideAttrs (_: {
        outputHash = "sha256-unyJ7ykJ6Fiq7IZZP1wU+yRkmJlX7QV7Wdx9CNRir5k=";
      });
    });
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
