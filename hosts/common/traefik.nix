{ config, pkgs, ... }:
{
  virtualisation.podman.dockerSocket.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.enable = true;
  users.groups.podman.members = [ "traefik" ];

  networking.firewall.allowedTCPPorts = [
    80
    443
    8080
  ];
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entrypoint = {
           to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http.tls.certResolver = "letsencrypt";
        };
      };

      providers = {
        docker = {
          endpoint = "unix:///var/run/docker.sock";
          exposedByDefault = false;
        };
      };

      certificatesResolvers.letsencrypt = {
        acme = {
          email = "me@dh274.com";
          storage = "${config.services.traefik.dataDir}/acme.json";
          httpChallenge.entryPoint = "web";
        };
      };
      log = {
        level = "INFO";
        filePath = "${config.services.traefik.dataDir}/traefik.log";
        format = "json";
      };
      api.dashboard = true;
      api.insecure = true;
    };
    dynamicConfigOptions = {
      http.middlewares = {
        oauth2-auth.forwardAuth = {
          address = "http://localhost:4180/";
          trustForwardHeader = "true";
          authResponseHeaders = [
            "X-Auth-Request-Email"
            "X-Auth-Request-User"
          ];
        };
      };
      http.routers = {
        docker-multiuser = {
          rule = "Host(`ftpclient.38c3.tschunk.social`)";
          service = "docker-multiuser";
          middlewares = [ "oauth2-auth" ];
        };
      };
      http.services = {
        docker-multiuser.loadBalancer.servers = [ { url = "http://localhost:5000"; } ];
      };
    };
  };
}
