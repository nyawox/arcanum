{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
let
  inherit (lib) strings;
  inherit (lib) singleton;
  z =
    {
      domain,
      url,
      auth ? false,
      groups ? [ ],
      basicAuth ? false,
      internal ? false,
      noLog ? false,
      waf ? true,
      extraConfig ? "",
      extraReverseProxyConfig ? "",
      beforeReverseProxyDir ? "",
      beforeHandle ? "",
    }:
    {
      inherit
        domain
        url
        auth
        groups
        basicAuth
        internal
        noLog
        waf
        extraConfig
        extraReverseProxyConfig
        beforeReverseProxyDir
        beforeHandle
        ;
    };
  reverseProxy = [
    (z {
      domain = "admin-apps.${arcanum.domain}";
      url = "lokalhost.${arcanum.internal}:8082";
      auth = true;
      groups = [ "dashboard" ];
    })
    (z {
      domain = "search.${arcanum.domain}";
      url = "lokalhost.${arcanum.internal}:8420";
      auth = true;
      groups = [ "search" ];
    })
    (z {
      domain = "mail.${arcanum.domain}";
      url = "localhoax.${arcanum.internal}:8416";
      auth = true;
      groups = [ "webmail" ];
    })
    (z {
      domain = "vault.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:3011";
    })
    (z {
      domain = "cal.${arcanum.domain}";
      url = "lokalhost.${arcanum.internal}:8642";
    })
    (z {
      domain = "docs.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:28198";
    })
    (z {
      domain = "recipes.${arcanum.domain}";
      url = "localtoast.${arcanum.internal}:8949";
      auth = true;
      groups = [ "mealie" ];
    })
    (z {
      domain = "minio.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:9315";
      auth = true;
      groups = [ "minio" ];
    })
    (z {
      domain = "s3.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:9314";
      noLog = true; # This overloads log parsers. we can handle this in client side
      waf = false; # becomes irresponsible
      # keep access to metrics internal only
      beforeHandle = ''
        handle /minio/v2/metrics/* {
          respond "Access denied" 403
        }
      '';
    })
    (z {
      domain = "hs.${arcanum.domain}";
      url = "https://lokalhost.${arcanum.internal}:8085";
      noLog = true; # This overloads log parsers. we can handle this in client side
      beforeHandle = ''
        ${oauth2-directive}
        redir /admin /admin/ 301
        handle /admin/* {
          ${forward-auth [ "vpn" ]}
          reverse_proxy http://lokalhost:${arcanum.internal}:9191
        }
      '';
    })
    (z {
      domain = "oauth2.${arcanum.domain}";
      url = "lokalhost.${arcanum.internal}:16544";
    })
    (z {
      domain = "account.${arcanum.domain}";
      url = "https://lokalhost.${arcanum.internal}:4348";
    })
    (z {
      domain = "llm.${arcanum.domain}";
      url = "localhoax.${arcanum.internal}:11454";
      auth = true;
      groups = [ "llm" ];
      beforeHandle = ''
        handle /api/* {
          reverse_proxy localhoax.${arcanum.internal}:11454
        }
      '';
    })
    (z {
      domain = "hass.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:8123";
    })
    (z {
      domain = "adguard.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:3380";
      auth = true;
      groups = [ "adguard" ];
    })
    (z {
      domain = "adguard-2.${arcanum.domain}";
      url = "localtoast.${arcanum.internal}:3380";
      auth = true;
      groups = [ "adguard" ];
    })
    (z {
      domain = "books.${arcanum.domain}";
      url = "localtoast.${arcanum.internal}:10801";
      auth = true;
      groups = [ "books" ];
      beforeHandle = ''
        @apis {
          path /koreader/* /opds/*
        }
        handle @apis {
          reverse_proxy localtoast.${arcanum.internal}:10801
        }
      '';
    })
    (z {
      domain = "git.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:3145";
      auth = true;
      groups = [ "git" ];
    })
    (z {
      domain = "health.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:8451";
    })
    (z {
      domain = "prometheus.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:9090";
      auth = true;
      groups = [ "prometheus" ];
    })
    (z {
      domain = "alerts.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:9844";
      auth = true;
      groups = [ "prometheus" ];
    })
    (z {
      domain = "grafana.${arcanum.domain}";
      url = "localpost.${arcanum.internal}:3175";
      auth = true;
      groups = [ "grafana" ];
    })
  ];

  expire-header =
    # bash
    ''
      @static {
        file
        path *.ico *.css *.js *.gif *.jpg *.jpeg *.png *.svg *.woff
      }
      header @static Cache-Control max-age=5184000
    '';
  common-header =
    #bash
    ''
      header * {
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "no-referrer"
        X-Robots-Tag "noindex, noarchive, nofollow"
        X-Frame-Options "SAMEORIGIN"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy "strict-origin-when-cross-origin"
      }
    '';
  encode =
    # bash
    ''
      encode gzip zstd
    '';
  oauth2-directive =
    # bash
    ''
      handle /oauth2/* {
        reverse_proxy lokalhost.${arcanum.internal}:16544 {
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-Uri {uri}
        }
      }
    '';
  forward-auth =
    groups:
    # bash
    ''
      forward_auth lokalhost.${arcanum.internal}:16544 {
        uri /oauth2/auth${
          lib.optionalString (groups != [ ]) "?allowed_groups=${lib.concatStringsSep "," groups}"
        }
        header_up X-Real-IP {remote_host}
        copy_headers X-Auth-Request-User X-Auth-Request-Email
        @error status 401 403
        handle_response @error {
          redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
        }
      }
    '';
  block-external-ips =
    # bash
    ''
      @blocked not remote_ip 100.64.0.0/10 10.0.0.0/8 127.0.0.1 localhost ::1
      respond @blocked "Access denied" 403
    '';
  geoblock =
    # bash
    ''
      @geoblock {
        not maxmind_geolocation {
          db_path "/var/lib/GeoIP/GeoLite2-City.mmdb"
          # they should've been using vpn anyway
          deny_countries CN
        }
      }
      respond @geoblock "Access denied" 403
    '';
  mkReverseProxy = values: {
    useACMEHost = "${arcanum.domain}";
    extraConfig = strings.concatStrings [
      expire-header
      common-header
      encode
      # bash
      ''
        route {
          ${geoblock}
          crowdsec
          ${(if values.waf then "appsec" else "")}
      ''
      (if values.internal then block-external-ips else "")
      (if values.auth then oauth2-directive else "")
      # bash
      ''
        ${values.beforeHandle}
        handle {
            ${if values.auth then (forward-auth values.groups) else ""}
            ${values.beforeReverseProxyDir}
            reverse_proxy ${values.url} {
              header_up X-Real-IP {remote_host}
              ${values.extraReverseProxyConfig}
            }
          }
        }
      ''
      values.extraConfig
    ];
    logFormat = ''
      ${
        if values.noLog then
          # bash
          ''
            output discard
          ''
        else
          # bash
          ''
            output file ${config.services.caddy.logDir}/access-${values.domain}.log {
              roll_size 1GiB
              roll_keep 0
              mode 640
            }
          ''
      }
    '';
  };

  mkVirtualHosts =
    values:
    builtins.listToAttrs (
      map (conf: {
        name = conf.domain;
        value = mkReverseProxy conf;
      }) values
    );
in
{
  content = {
    sops.secrets.caddy-env = {
      sopsFile = "${arcanum.secretPath}/caddy-secrets.yaml";
      owner = config.systemd.services.caddy.serviceConfig.User;
      format = "yaml";
      reloadUnits = [ "caddy.service" ];
    };
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/hslatman/caddy-crowdsec-bouncer@v0.7.3-0.20241204230608-a681cdc5077b"
          "github.com/porech/caddy-maxmind-geolocation@v0.0.0-20240808060618-c7dd9b5c8231"
        ];
        hash = "sha256-J8cCbrzeppwaOFdf194vFgY5m5osVSV8zvUBUYUANDE=";
      };
      logFormat = # bash
        ''
          level INFO
          format json
        '';
      # prometheus
      globalConfig = # bash
        ''
          admin 0.0.0.0:2019
          metrics
          servers {
            trusted_proxies static 10.100.0.0/24
            max_header_size 5MB
            enable_full_duplex
          }
          crowdsec {
            api_url http://lokalhost.${arcanum.internal}:6484
            api_key {$CADDY_CROWDSEC_API_KEY}
            ticker_interval 15s
            appsec_url http://lokalhost.${arcanum.internal}:7424
            #disable_streaming
            #enable_hard_fails
          }
        '';
      virtualHosts = mkVirtualHosts reverseProxy // {
        "${arcanum.domain}" = {
          useACMEHost = "${arcanum.domain}";
          extraConfig = strings.concatStrings [
            expire-header
            encode
            # bash
            ''
              # redirect to nonexistent www, which should give 404
              redir https://www.${arcanum.domain}{uri} permanent
            ''
          ];
          logFormat = ''
            output discard
          '';
        };
        "*.${arcanum.domain}" = {
          useACMEHost = "${arcanum.domain}";
          extraConfig = strings.concatStrings [
            expire-header
            encode
            # bash
            ''
              header Content-Type text/html
              route {
                ${geoblock}
                crowdsec
                appsec
                respond <<EOF
                <html>
                <head>
                    <title>Page not found</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                        body {
                            margin: 0;
                            font-family: sans-serif;
                        }
                        .wrapping-yapping {
                            display: flex;
                            justify-content: center;
                            align-items: center;
                            height: 100vh;
                            background-color: #1e1e2e;
                        }
                        .flexing-flexy {
                            width: 90%;
                            max-width: 600px;
                            padding: 20px;
                            background-color: #313244;
                            color: #cad3f5;
                            text-align: center;
                            border-radius: 8px;
                            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
                        }
                        .flexing-flexy img {
                            max-width: 100%;
                            height: auto;
                            margin-bottom: 20px;
                        }
                        .flexing-flexy h1 {
                          color: #eed49f;
                          font-size: 1.5em;
                          line-height: 1.5;
                        }
                        .flexing-flexy p {
                          font-size: 1.2em;
                          line-height: 1.5;
                        }
                        .flexing-flexy a {
                          color: #8aadf4;
                          text-decoration: none;
                          font-weight: bold;
                        }
                        .flexing-flexy a:hover {
                          text-decoration: underline;
                        }
                    </style>
                </head>
                <body>
                    <div class="wrapping-yapping">
                        <div class="flexing-flexy">
                            <img src="https://http.cat/404">
                            <h1>404</h1>
                            <p>Oops! The page you're looking for could not be found.</p>
                            <p>Please check the URL.</p>
                        </div>
                    </div>
                </body>
                </html>
                EOF 404
              }
            ''
          ];
          logFormat = # bash
            ''
              output file ${config.services.caddy.logDir}/access-*.${arcanum.domain}.log {
                roll_size 1GiB
                roll_keep 0
                mode 640
              }
            '';
        };
      };
    };
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    users.users.caddy.extraGroups = singleton "acme";
    systemd.services = {
      caddy = {
        serviceConfig.LogsDirectoryMode = "0750";
        serviceConfig.EnvironmentFile = "${config.sops.secrets.caddy-env.path}";
      };
      promtail = {
        startLimitIntervalSec = 0;
        wants = singleton "geoipupdate.service";
        after = singleton "geoipupdate.service";
      };
    };
    modules.monitoring.promtail.enable = true;
    users.users.promtail.extraGroups = singleton "caddy";
    services.promtail.configuration.scrape_configs = singleton {
      job_name = "caddy";
      static_configs = singleton {
        targets = singleton "localhost";
        labels = {
          job = "caddy";
          __path__ = "/var/log/caddy/*.log";
          # clutters the log too much
          __path_exclude__ = "/var/log/caddy/access-{s3,hs,health}*.log";
          agent = "caddy-promtail";
        };
      };
      pipeline_stages = [
        {
          json.expressions = {
            duration = "duration";
            status = "status";
            remote_ip = "request.remote_ip";
          };
        }
        {
          labels = {
            duration = null;
            status = null;
          };
        }
        {
          geoip = {
            db = "/var/lib/GeoIP/GeoLite2-City.mmdb";
            source = "remote_ip";
            db_type = "city";
          };
        }
      ];
    };
    modules.services.geoip.enable = true;
  };
}
