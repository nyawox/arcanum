{
  config,
  lib,
  arcanum,
  ...
}:
with lib;
{
  content = {
    services.prometheus = {
      enable = true;
      webExternalUrl = "https://prometheus.${arcanum.domain}";
      listenAddress = "0.0.0.0";
      port = 9090;
      scrapeConfigs = [
        {
          job_name = "nodes";
          scrape_interval = "15s";
          scrape_timeout = "12s";
          static_configs = [
            {
              targets = [
                "localpost.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "localtoast.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "lolcathost.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "lokalhost.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "localhoax.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "localghost.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "localcoast.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
                "localhostage.${arcanum.internal}:${toString config.services.prometheus.exporters.node.port}"
              ];
            }
          ];
        }
        {
          job_name = "prometheus";
          static_configs = singleton { targets = singleton "localpost.${arcanum.internal}:9090"; };
        }
        {
          job_name = "alertmanager";
          static_configs = singleton { targets = singleton "localpost.${arcanum.internal}:9844"; };
        }
        {
          job_name = "postgres";
          static_configs = singleton {
            targets = [
              "localpost.${arcanum.internal}:9187"
              "localhoax.${arcanum.internal}:9187"
            ];
          };
        }
        {
          job_name = "minio";
          metrics_path = "/minio/v2/metrics/cluster";
          scheme = "http";
          static_configs = singleton { targets = singleton "localpost.${arcanum.internal}:9314"; };
        }
        {
          job_name = "crowdsec";
          static_configs = singleton {
            targets = [
              "localpost.${arcanum.internal}:6764"
              "localtoast.${arcanum.internal}:6764"
              "lolcathost.${arcanum.internal}:6764"
              "lokalhost.${arcanum.internal}:6764"
              "localhoax.${arcanum.internal}:6764"
              "localghost.${arcanum.internal}:6764"
              "localcoast.${arcanum.internal}:6764"
              "localhostage.${arcanum.internal}:6764"
            ];
          };
        }
        {
          job_name = "endlessh";
          static_configs = singleton {
            targets = [
              "lokalhost.${arcanum.internal}:9164"
              "localhoax.${arcanum.internal}:9164"
              "localghost.${arcanum.internal}:9164"
              "localcoast.${arcanum.internal}:9164"
              "localhostage.${arcanum.internal}:9164"
            ];
          };
        }
        {
          job_name = "adguard";
          scrape_interval = "15s";
          static_configs = [
            {
              targets = [
                "localpost.${arcanum.internal}:9618"
                "localtoast.${arcanum.internal}:9618"
              ];
            }
          ];
        }
        {
          job_name = "caddy";
          static_configs = singleton {
            targets = singleton "lokalhost.${arcanum.internal}:2019";
          };
        }
        {
          job_name = "wireguard";
          static_configs = singleton {
            targets = [
              "localpost.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "localtoast.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "lolcathost.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "lokalhost.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "localhoax.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "localghost.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "localcoast.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
              "localhostage.${arcanum.internal}:${toString config.services.prometheus.exporters.wireguard.port}"
            ];
          };
        }
      ];
    };
  };
  persist.directories = singleton "/var/lib/prometheus2"; # services.prometheus.stateDir
}
