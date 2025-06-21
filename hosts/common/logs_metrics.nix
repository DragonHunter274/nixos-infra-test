{ config, pkgs, ... }:

{
  # enable syslogs
  services.syslog-ng.enable = true;
  
  # grafana configuration
  services.grafana = {
    enable = true;
    settings.server = {
      domain = "fablabmuc-38c3.tail96bd9b.ts.net";
      http_port = 2342;
      http_addr = "0.0.0.0";
    };
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
 
  # loki
  services.loki = {
    enable = true;
    configFile = ./loki.yaml;
  };

  # promtail
  systemd.services.promtail = {
    description = "Promtail service for Loki";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.grafana-loki}/bin/promtail --config.file ${./promtail.yaml}
      '';
    };
  };



}
