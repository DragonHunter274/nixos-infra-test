# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."oauth2-proxy" = {
    image = "quay.io/oauth2-proxy/oauth2-proxy:latest";
    environment = {
      "OAUTH2_PROXY_CLIENT_ID" = "Ov23liKH7rfJBxmBN0vI";
      "OAUTH2_PROXY_CLIENT_SECRET" = "99e4c67b304b2f7147926e29fa602507358a7ccc";
      "OAUTH2_PROXY_COOKIE_DOMAINS" = ".38c3.tschunk.social";
      "OAUTH2_PROXY_COOKIE_SECRET" = "acVnYPFTRTdvZ2ypgAKaTmBLy_isCpE9dH6FGLNbgBo=";
      "OAUTH2_PROXY_EMAIL_DOMAINS" = "*";
      "OAUTH2_PROXY_GITHUB_ORG" = "fablabmuc-38c3";
      "OAUTH2_PROXY_PASS_USER_HEADERS" = "true";
      "OAUTH2_PROXY_PROVIDER" = "github";
      "OAUTH2_PROXY_REDIRECT_URL" = "https://oauth2.38c3.tschunk.social/oauth2/callback";
      "OAUTH2_PROXY_REVERSE_PROXY" = "true";
      "OAUTH2_PROXY_SET_XAUTHREQUEST" = "true";
      "OAUTH2_PROXY_SHOW_DEBUG_ON_ERROR" = "true";
      "OAUTH2_PROXY_UPSTREAMS" = "static://202";
      "OAUTH2_PROXY_WHITELIST_DOMAINS" = ".38c3.tschunk.social";
    };
    ports = [
      "4180:4180/tcp"
    ];
    cmd = [ "--http-address=0.0.0.0:4180" ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.oauth2.entrypoints" = "websecure";
      "traefik.http.routers.oauth2.rule" = "(Host(`oauth2.38c3.tschunk.social`) && PathPrefix(`/oauth2/`)) || (PathPrefix(`/oauth2/`))";
      "traefik.http.routers.oauth2.tls" = "true";
      "traefik.http.routers.oauth2.tls.certResolver" = "letsencrypt";
      "traefik.http.services.oauth2.loadbalancer.server.port" = "4180";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=oauth2-proxy"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-oauth2-proxy" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-traefik-test_default.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."prowlarr" = {
    image = "ghcr.io/linuxserver/prowlarr:latest";
    environment = {
      "PGID" = "1000";
      "PUID" = "1000";
      "TZ" = "Europe/paris";
    };
    volumes = [
      "traefik-test_prowlarr-data:/config:rw"
    ];
    ports = [
      "9696:9696/tcp"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.prowlarr.entryPoints" = "websecure";
      "traefik.http.routers.prowlarr.middlewares" = "oauth2-auth@file";
      "traefik.http.routers.prowlarr.rule" = "Host(`prowlarr.38c3.tschunk.social`)";
      "traefik.http.routers.prowlarr.tls.certResolver" = "letsencrypt";
      "traefik.http.services.prowlarr.loadbalancer.server.port" = "9696";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=prowlarr"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-prowlarr" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_prowlarr-data.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_prowlarr-data.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."qbittorrent" = {
    image = "ghcr.io/hotio/qbittorrent";
    environment = {
      "PGID" = "1000";
      "PUID" = "1000";
      "TZ" = "Etc/UTC";
      "UMASK" = "002";
      "WEBUI_PORTS" = "8080/tcp,8080/udp";
    };
    volumes = [
      "traefik-test_qbittorrent-data:/config:rw"
      "traefik-test_shared-download:/data:rw"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.torrent.entryPoints" = "websecure";
      "traefik.http.routers.torrent.middlewares" = "oauth2-auth@file";
      "traefik.http.routers.torrent.rule" = "Host(`torrent.38c3.tschunk.social`)";
      "traefik.http.routers.torrent.tls.certResolver" = "letsencrypt";
      "traefik.http.services.torrent.loadbalancer.server.port" = "8080";
      "traefik.port" = "8080";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=qbittorrent"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-qbittorrent" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_qbittorrent-data.service"
      "podman-volume-traefik-test_shared-download.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_qbittorrent-data.service"
      "podman-volume-traefik-test_shared-download.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."radarr" = {
    image = "linuxserver/radarr:latest";
    environment = {
      "PGID" = "1000";
      "PUID" = "1000";
      "TZ" = "Europe/paris";
    };
    volumes = [
      "/slow/media/radarr-out:/out:rw"
      "traefik-test_radarr-data:/config:rw"
    ];
    ports = [
      "7676:7878/tcp"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.radarr.entryPoints" = "websecure";
      "traefik.http.routers.radarr.middlewares" = "oauth2-auth@file";
      "traefik.http.routers.radarr.rule" = "Host(`radarr.38c3.tschunk.social`)";
      "traefik.http.routers.radarr.tls.certResolver" = "letsencrypt";
      "traefik.http.services.radarr.loadbalancer.server.port" = "7878";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=radarr"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-radarr" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_radarr-data.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_radarr-data.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."simple-service" = {
    image = "mendhak/http-https-echo";
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.whoami.entryPoints" = "websecure";
      "traefik.http.routers.whoami.middlewares" = "oauth2-auth@file";
      "traefik.http.routers.whoami.rule" = "Host(`whoami.38c3.tschunk.social`)";
      "traefik.http.routers.whoami.tls.certResolver" = "letsencrypt";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=whoami"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-simple-service" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-traefik-test_default.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."sonarr" = {
    image = "ghcr.io/linuxserver/sonarr:latest";
    environment = {
      "DOCKER_MODS" = "ghcr.io/gilbn/theme.park:sonarr";
      "PGID" = "1000";
      "PUID" = "1000";
      "TP_THEME" = "organizr";
      "TZ" = "Europe/paris";
    };
    volumes = [
      "/slow/media/sonarr-out:/out:rw"
      "traefik-test_sonarr-data:/config:rw"
    ];
    ports = [
      "7878:7878/tcp"
      "8989:8989/tcp"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.sonarr.entryPoints" = "websecure";
      "traefik.http.routers.sonarr.middlewares" = "oauth2-auth@file";
      "traefik.http.routers.sonarr.rule" = "Host(`sonarr.38c3.tschunk.social`)";
      "traefik.http.routers.sonarr.tls.certResolver" = "letsencrypt";
      "traefik.http.services.sonarr.loadbalancer.server.port" = "8989";
      "traefik.port" = "8989";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=sonarr"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-sonarr" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_sonarr-data.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
      "podman-volume-traefik-test_sonarr-data.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."unbound" = {
    image = "ghcr.io/dragonhunter274/unbound-docker:latest";
    volumes = [
      "/etc/unbound/conf.d/:/usr/local/unbound/conf.d:rw"
    ];
    ports = [
      "53:5335/tcp"
      "53:5335/udp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=/usr/local/unbound/sbin/healthcheck.sh"
      "--health-interval=1m0s"
      "--health-retries=5"
      "--health-start-period=15s"
      "--health-timeout=30s"
      "--network-alias=unbound"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-unbound" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-traefik-test_default.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };
  virtualisation.oci-containers.containers."whoami" = {
    image = "traefik/whoami";
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.whoami2.entryPoints" = "websecure";
      "traefik.http.routers.whoami2.middlewares" = "oauth2-auth@file";
      "traefik.http.routers.whoami2.rule" = "Host(`whoami.38c3.tschunk.social`) && Header(`x-auth-request-user`, `DragonHunter274`)";
      "traefik.http.routers.whoami2.tls.certResolver" = "letsencrypt";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=whoami2"
      "--network=traefik-test_default"
    ];
  };
  systemd.services."podman-whoami" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "no";
    };
    after = [
      "podman-network-traefik-test_default.service"
    ];
    requires = [
      "podman-network-traefik-test_default.service"
    ];
    partOf = [
      "podman-compose-traefik-test-root.target"
    ];
    wantedBy = [
      "podman-compose-traefik-test-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-traefik-test_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f traefik-test_default";
    };
    script = ''
      podman network inspect traefik-test_default || podman network create traefik-test_default
    '';
    partOf = [ "podman-compose-traefik-test-root.target" ];
    wantedBy = [ "podman-compose-traefik-test-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-traefik-test_prowlarr-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect traefik-test_prowlarr-data || podman volume create traefik-test_prowlarr-data
    '';
    partOf = [ "podman-compose-traefik-test-root.target" ];
    wantedBy = [ "podman-compose-traefik-test-root.target" ];
  };
  systemd.services."podman-volume-traefik-test_qbittorrent-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect traefik-test_qbittorrent-data || podman volume create traefik-test_qbittorrent-data
    '';
    partOf = [ "podman-compose-traefik-test-root.target" ];
    wantedBy = [ "podman-compose-traefik-test-root.target" ];
  };
  systemd.services."podman-volume-traefik-test_radarr-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect traefik-test_radarr-data || podman volume create traefik-test_radarr-data
    '';
    partOf = [ "podman-compose-traefik-test-root.target" ];
    wantedBy = [ "podman-compose-traefik-test-root.target" ];
  };
  systemd.services."podman-volume-traefik-test_shared-download" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect traefik-test_shared-download || podman volume create traefik-test_shared-download
    '';
    partOf = [ "podman-compose-traefik-test-root.target" ];
    wantedBy = [ "podman-compose-traefik-test-root.target" ];
  };
  systemd.services."podman-volume-traefik-test_sonarr-data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect traefik-test_sonarr-data || podman volume create traefik-test_sonarr-data
    '';
    partOf = [ "podman-compose-traefik-test-root.target" ];
    wantedBy = [ "podman-compose-traefik-test-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-traefik-test-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
