{
  cfg,
  config,
  lib,
  inputs,
  pkgs,
  hostname,
  arcanum,
  ...
}:
with lib;
let
  domain = "hs.${arcanum.domain}";
  derpPort = 3478;
in
{
  options.subdomain = mkOption {
    type = types.str;
    default = "hsnet";
  };

  content = {
    nixpkgs.overlays = [ inputs.headscale.overlay ];
    sops.secrets = {
      headscale-acls = {
        sopsFile = "${arcanum.secretPath}/headscale-secrets.yaml";
        owner = config.services.headscale.user;
        inherit (config.services.headscale) group;
        format = "yaml";
        restartUnits = [ "headscale.service" ];
      };
      headscale-oidc = {
        sopsFile = "${arcanum.secretPath}/headscale-secrets.yaml";
        owner = config.services.headscale.user;
        inherit (config.services.headscale) group;
        format = "yaml";
        restartUnits = [ "headscale.service" ];
      };
    };
    services = {
      headscale = {
        enable = true;
        package = inputs.headscale.packages.${pkgs.system}.headscale.overrideAttrs (_old: {
          # silence the warning
          meta.mainProgram = "headscale";
        });
        address = "[::]";
        port = 8085;
        settings = {
          dns = {
            magic_dns = true;
            base_domain = "${cfg.subdomain}.${arcanum.domain}";
            nameservers.global = [
              # AdGuard Home
              "10.100.0.2" # localpost fixed wg ip
              "10.100.0.4" # localtoast fixed wg ip
              "100.64.0.9" # localpost-ts
              "100.64.0.10" # localtoast-ts
              "127.0.0.1" # keep localhost, otherwise sometimes it fails to connect
              # Add quad9 back when adguard home is down(e.g. reinstalling headscale)
              # "9.9.9.9"
              # "149.112.112.112"
            ];
          };
          logtail.enabled = false;
          policy.path = config.sops.secrets.headscale-acls.path;
          server_url = "https://${domain}"; # must be https to preserve headers. ignore the warning
          prefixes = {
            v6 = "fd7a:115c:a1e0::/48";
            v4 = "100.64.0.0/10";
          };
          database = {
            type = "sqlite3";
            sqlite = {
              path = "/var/lib/headscale/db.sqlite";
              write_ahead_log = true;
            };
          };

          # issued for internal domain
          tls_key_path = "/var/lib/acme/${arcanum.domain}/key.pem";
          tls_cert_path = "/var/lib/acme/${arcanum.domain}/cert.pem";

          derp.server = {
            enabled = true;
            region_id = 999;
            region_code = hostname;
            region_name = hostname + " DERP";
            stun_listen_addr = "[::]:${toString derpPort}";
          };
          derp.urls = [ ];
          oidc = {
            only_start_if_oidc_is_available = true;
            issuer = "https://account.${arcanum.domain}/oauth2/openid/headscale";
            client_id = "headscale";
            client_secret_path = config.sops.secrets.headscale-oidc.path;
            scope = [
              "openid"
              "profile"
              "email"
            ];
            pkce = {
              enabled = true;
              method = "S256";
            };
            map_legacy_users = false;
          };
        };
      };
    };
    systemd.services.headscale.after = [ "kanidm.service" ];
    modules.backup.restic = {
      enable = true;
      list = [
        {
          name = "headscale";
          path = "/var/lib/headscale";
        }
      ];
    };

    users.users.headscale.extraGroups = [
      "acme"
      "caddy"
    ]; # for some reason caddy group owns the cert

    environment.systemPackages = [ config.services.headscale.package ];
    networking.firewall.allowedUDPPorts = [ derpPort ];
  };
  persist.directories = singleton {
    directory = "/var/lib/headscale";
    user = "headscale";
    group = "headscale";
    mode = "750";
  };
}
