{
  config,
  lib,
  pkgs,
  arcanum,
  hostname,
  ...
}:
with lib;
{
  extraConfig = [
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-grafana = {
        sopsFile = "${arcanum.secretPath}/grafana-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "grafana" ];
        ensureUsers = singleton {
          name = "grafana";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-grafana.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "grafana" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  content = {
    sops.secrets = {
      grafana-oidc = {
        sopsFile = "${arcanum.secretPath}/grafana-secrets.yaml";
        owner = config.systemd.services.grafana.serviceConfig.User;
        format = "yaml";
      };
      grafana-postgres = {
        sopsFile = "${arcanum.secretPath}/grafana-secrets.yaml";
        owner = config.systemd.services.grafana.serviceConfig.User;
        format = "yaml";
      };
    };
    systemd.services.grafana.after = [ "postgresql.service" ];
    services.grafana = {
      enable = true;
      settings = {
        analytics = {
          feedback_links_enabled = false;
          reporting_enabled = false;
        };
        database = {
          type = "postgres";
          name = "grafana";
          user = "grafana";
          host = "localpost.${arcanum.internal}:5432";
          password = "$__file{${config.sops.secrets.grafana-postgres.path}}";
        };
        security = {
          cookie_secure = true;
          csrf_trusted_origins = [
            "https://account.${arcanum.domain}"
            "https://oauth2.${arcanum.domain}"
          ];
          disable_initial_admin_creation = true;
        };
        server = {
          enable_gzip = false; # caddy already do this
          domain = "grafana.${arcanum.domain}";
          root_url = "https://grafana.${arcanum.domain}/";
          enforce_domain = true;
          http_addr = "0.0.0.0";
          http_port = 3175;
          router_logging = true;
        };
        "auth.anonymous".enabled = false;
        "auth.basic".enabled = false;
        "auth.generic_oauth" = {
          enabled = true;
          name = "${arcanum.serviceName} Account";
          icon = "signin";
          client_id = "grafana";
          client_secret = "$__file{${config.sops.secrets.grafana-oidc.path}}";
          auth_url = "https://account.${arcanum.domain}/ui/oauth2";
          token_url = "https://account.${arcanum.domain}/oauth2/token";
          api_url = "https://account.${arcanum.domain}/oauth2/openid/grafana/userinfo";
          scopes = [
            "openid"
            "email"
            "profile"
          ];
          use_pkce = true;
          use_refresh_token = true;
          allow_sign_up = true;
          login_attribute_path = "preferred_username";
          groups_attribute_path = "groups";
          allow_assign_grafana_admin = true;
          role_attribute_path = "contains(grafana_role[*], 'GrafanaAdmin') && 'GrafanaAdmin' || contains(grafana_role[*], 'Admin') && 'Admin' || contains(grafana_role[*], 'Editor') && 'Editor' || 'Viewer'";
        };
      };
      provision = {
        enable = true;
        dashboards.settings.providers =
          let
            # fix the stupid datasource named ${DS_PROMETHEUS} was not found issue https://github.com/grafana/grafana/issues/10786
            patchDashboard =
              {
                name,
                url,
                sha256,
                extraPatches ? "",
              }:
              let
                orig = pkgs.fetchurl {
                  inherit name url sha256;
                };
              in
              pkgs.runCommand name
                {
                  nativeBuildInputs = [ pkgs.gnused ];
                }
                ''
                  cp ${orig} $out
                  sed -i 's/''${DS_PROMETHEUS}/Prometheus/g' $out
                  sed -i 's/''${DS_LOKI}/Loki/g' $out
                  ${extraPatches}
                '';
          in
          [
            {
              name = "node-exporter-full";
              type = "file";
              options.path = pkgs.fetchurl {
                name = "node-exporter-full.json"; # the name have to match
                url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
                sha256 = "0qza4j8lywrj08bqbww52dgh2p2b9rkhq5p313g72i57lrlkacfl";
              };
            }
            {
              name = "postgres-exporter";
              type = "file";
              options.path = pkgs.fetchurl {
                name = "postgres-exporter.json";
                url = "https://grafana.com/api/dashboards/9628/revisions/8/download";
                sha256 = "1iwwqglszdl3wmsl86z9fjd8wlp019aq9hsz4pgxxjjv0qsaq6sj";
              };
            }
            {
              name = "adguard-exporter";
              type = "file";
              options.path = patchDashboard {
                name = "adguard-exporter.json";
                url = "https://grafana.com/api/dashboards/20799/revisions/7/download";
                sha256 = "1n3yh7msdjlm1ph7a566nb2hhlyr4mfk37alsd2190x60pscjkc3";
              };
            }
            {
              name = "endlessh";
              type = "file";
              options.path = patchDashboard {
                name = "endlessh.json";
                url = "https://grafana.com/api/dashboards/15156/revisions/12/download";
                sha256 = "04rbiqymafimm6sy76bjr7ayskx36jrk7zy4n936va6x51jdb8ya";
              };
            }
            {
              name = "minio";
              type = "file";
              options.path = patchDashboard {
                name = "minio.json";
                url = "https://grafana.com/api/dashboards/13502/revisions/26/download";
                sha256 = "1pfps3n47sfl89lhy8k1g355cbmy3za086l61icmxrchhdbd66q8";
              };
            }
            {
              name = "crowdsec-metrics";
              type = "file";
              options.path = patchDashboard {
                name = "crowdsec-metrics.json";
                url = "https://grafana.com/api/dashboards/21419/revisions/1/download";
                sha256 = "17rvx8q3sp7b9y302ddswjm9xvp98j3mplxjbyvib79rbyvj2wxs";
              };
            }
            {
              name = "postfix-delivery-status";
              type = "file";
              options.path = patchDashboard {
                name = "postfix-delivery-status.json";
                url = "https://grafana.com/api/dashboards/20574/revisions/2/download";
                sha256 = "1b8jppmdsvgxn2v7hf4cnq87d604dpwdn4azx5nvcmb3l6rgdp7i";
                extraPatches = "sed -i 's/mail.log/postfix.log/g' $out";
              };
            }
            {
              # geomap
              name = "caddy";
              type = "file";
              options.path = "${arcanum.configPath}/monitoring/grafana/caddy.json";
            }
            {
              name = "wireguard";
              type = "file";
              options.path = "${arcanum.configPath}/monitoring/grafana/wireguard.json";
            }
          ];
        datasources.settings = {
          # with http:// protocol prefix
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localpost.${arcanum.internal}:9090";
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://localtoast.${arcanum.internal}:3154";
              access = "proxy";
              jsonData = {
                timeout = 600;
              };
            }
          ];
          # cannot delete from dashboard
          deleteDatasources = [
            {
              name = "loki";
              orgId = 1;
            }
          ];
        };
      };
    };
  };
  persist.directories = singleton "/var/lib/grafana";
}
