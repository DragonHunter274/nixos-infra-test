{ config, pkgs, ... }:

{
  # enable syslogs
  services.syslog-ng.enable = true;
  
  # grafana configuration
  services.grafana = {
    enable = true;
    domain = "fablabmuc-38c3.tail96bd9b.ts.net";
    port = 2342;
    addr = "127.0.0.1";
  };

  # prometheus config
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "saugomate_node_export";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];

  };


  # nginx reverse proxy
  services.nginx.virtualHosts.${config.services.grafana.domain} = {
    listen = [
      {
        addr = "0.0.0.0";
        port = 2222;
      }
    ];

    locations."/grafana" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
        proxyWebsockets = true;
    };
  };

}
