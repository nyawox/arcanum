{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  mkSecret = _name: {
    sopsFile = "${arcanum.secretPath}/kanidm-secrets.yaml";
    owner = "kanidm";
    format = "yaml";
    restartUnits = [ "kanidm.service" ];
  };
  mkOAuth2 =
    {
      displayName,
      originUrl,
      originLanding,
      scopes ? [
        "openid"
        "profile"
        "email"
      ],
      groups ? [ ],
      extraConfig ? { },
    }:
    {
      inherit displayName;
      inherit originUrl;
      inherit originLanding;
      preferShortUsername = true;
      scopeMaps = genAttrs groups (_group: scopes);
    }
    // extraConfig;

  commonGroups = [
    "vpn.users"
    "vpn.admins"
    "grafana.superadmins"
    "grafana.admins"
    "grafana.users"
    "grafana.guests"
    "mealie.users"
    "mealie.admins"
    "paperless.users"
    "paperless.admins"
    "hass.users"
    "hass.admins"
    "git.users"
    "git.admins"
    "minio.users"
    "minio.admins"
    "llm.users"
    "llm.admins"
    "adguard.users"
    "prometheus.users"
    "search.users"
    "dashboard.users"
    "webmail.users"
    "books.users"
  ];

in
{
  content = {
    sops.secrets = builtins.listToAttrs (
      map
        (name: {
          inherit name;
          value = mkSecret name;
        })
        (
          map (service: "kanidm-${service}") [
            "admin"
            "idm-admin"
            "headscale"
            "oauth2-proxy"
            "llm"
            "grafana"
            "mealie"
            "paperless"
            "git"
            "minio"
            "hass"
          ]
        )
    );
    services.kanidm = {
      enableServer = true;
      # mkForce is used to set higher priority than the one in client module
      package = mkForce pkgs.kanidmWithSecretProvisioning_1_4;
      serverSettings = {
        bindaddress = "[::]:4348";
        ldapbindaddress = "[::]:8636";
        domain = "account.${arcanum.domain}";
        origin = "https://account.${arcanum.domain}";
        trust_x_forward_for = true;
        log_level = "debug";
        online_backup = {
          path = "/var/lib/kanidm/backup";
          schedule = "00 22 * * *";
          versions = 1; # let restic handle this
        };
        tls_key = "/var/lib/acme/${arcanum.domain}/key.pem";
        tls_chain = "/var/lib/acme/${arcanum.domain}/cert.pem";
      };

      provision = {
        enable = true;
        adminPasswordFile = config.sops.secrets.kanidm-admin.path;
        idmAdminPasswordFile = config.sops.secrets.kanidm-idm-admin.path;
        # kanidm login -D idm_admin
        # kanidm person credential create-reset-token <account_id>
        persons."nyawox" = {
          displayName = "nyawox";
          mailAddresses = [ "${arcanum.personalMail}" ];
          groups = commonGroups;
        };
        groups = genAttrs commonGroups (_: { });
        systems.oauth2 = {
          headscale = mkOAuth2 {
            displayName = "VPN";
            originUrl = [
              "https://hs.${arcanum.domain}/oidc/callback"
              "https://hs.${arcanum.domain}/admin/oidc/callback"
            ];
            originLanding = "https://hs.${arcanum.domain}/admin";
            groups = [ "vpn.users" ];
            extraConfig.basicSecretFile = config.sops.secrets.kanidm-headscale.path;
          };
          llm = mkOAuth2 {
            displayName = "LLM";
            originUrl = "https://llm.${arcanum.domain}/oauth/oidc/callback";
            originLanding = "https://llm.${arcanum.domain}";
            groups = [
              "llm.users"
              "llm.admins"
            ];
            extraConfig = {
              allowInsecureClientDisablePkce = true;
              basicSecretFile = config.sops.secrets.kanidm-llm.path;
              claimMaps.llm_role = {
                joinType = "array";
                valuesByGroup = {
                  "llm.users" = [ "user" ];
                  "llm.admins" = [ "admin" ];
                };
              };
            };
          };
          grafana = mkOAuth2 {
            displayName = "Grafana";
            originUrl = "https://grafana.${arcanum.domain}/login/generic_oauth";
            originLanding = "https://grafana.${arcanum.domain}";
            groups = [
              "grafana.admins"
              "grafana.superadmins"
              "grafana.users"
              "grafana.guests"
            ];
            extraConfig = {
              claimMaps.grafana_role = {
                joinType = "array";
                valuesByGroup = {
                  "grafana.superadmins" = [ "GrafanaAdmin" ];
                  "grafana.admins" = [ "Admin" ];
                  "grafana.users" = [ "Editor" ];
                };
              };
              basicSecretFile = config.sops.secrets.kanidm-grafana.path;
            };
          };
          mealie = mkOAuth2 {
            displayName = "Recipes";
            originUrl = "https://recipes.${arcanum.domain}/login";
            originLanding = "https://recipes.${arcanum.domain}";
            groups = [
              "mealie.users"
              "mealie.admins"
            ];
            extraConfig = {
              claimMaps.groups = {
                joinType = "array";
                valuesByGroup = {
                  "mealie.users" = [ "user" ];
                  "mealie.admins" = [ "admin" ];
                };
              };
              basicSecretFile = config.sops.secrets.kanidm-mealie.path;
            };
          };
          minio = mkOAuth2 {
            displayName = "S3";
            originUrl = "https://minio.${arcanum.domain}/oauth_callback";
            originLanding = "https://minio.${arcanum.domain}";
            groups = [
              "minio.users"
              "minio.admins"
            ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            extraConfig = {
              allowInsecureClientDisablePkce = true; # https://github.com/minio/minio/discussions/20239
              basicSecretFile = config.sops.secrets.kanidm-minio.path;
              claimMaps.policy = {
                joinType = "array";
                valuesByGroup = {
                  "minio.admins" = [ "consoleAdmin" ];
                  "minio.users" = [ "readwrite" ];
                };
              };
            };
          };
          hass = mkOAuth2 {
            displayName = "Home Assistant";
            originUrl = "https://hass.${arcanum.domain}/auth/oidc/callback";
            originLanding = "https://hass.${arcanum.domain}";
            groups = [
              "hass.users"
              "hass.admins"
            ];
            extraConfig = {
              claimMaps.hass_role = {
                joinType = "array";
                valuesByGroup = {
                  "hass.admins" = [ "admin" ];
                  "hass.users" = [ "user" ];
                };
              };
              basicSecretFile = config.sops.secrets.kanidm-hass.path;
            };
          };
          forgejo = mkOAuth2 {
            displayName = "Git";
            originUrl = "https://git.${arcanum.domain}/user/oauth2/${arcanum.domain}/callback";
            originLanding = "https://git.${arcanum.domain}";
            groups = [
              "git.users"
              "git.admins"
            ];
            extraConfig = {
              allowInsecureClientDisablePkce = true;
              basicSecretFile = config.sops.secrets.kanidm-git.path;
              claimMaps.groups = {
                joinType = "array";
                valuesByGroup = {
                  "git.admins" = [ "admin" ];
                  "git.users" = [ "user" ];
                };
              };
            };
          };
          paperless = mkOAuth2 {
            displayName = "Documents";
            originUrl = "https://docs.${arcanum.domain}/accounts/oidc/account/login/callback/";
            originLanding = "https://docs.${arcanum.domain}";
            groups = [
              "paperless.users"
              "paperless.admins"
            ];
            extraConfig = {
              basicSecretFile = config.sops.secrets.kanidm-paperless.path;
              claimMaps.groups = {
                joinType = "array";
                valuesByGroup = {
                  "paperless.users" = [ "user" ];
                  "paperless.admins" = [ "admin" ];
                };
              };
            };
          };
          oauth2-proxy = mkOAuth2 {
            displayName = "${arcanum.domain}";
            originUrl = "https://oauth2.${arcanum.domain}/oauth2/callback";
            originLanding = "https://oauth2.${arcanum.domain}/";
            groups = [
              "search.users"
              "mealie.users"
              "minio.users"
              "llm.users"
              "adguard.users"
              "git.users"
              "prometheus.users"
              "grafana.users"
              "grafana.guests"
              "vpn.admins"
              "dashboard.users"
              "webmail.users"
              "books.users"
            ];
            extraConfig = {
              basicSecretFile = config.sops.secrets.kanidm-oauth2-proxy.path;
              claimMaps.groups = {
                joinType = "array";
                valuesByGroup = {
                  "search.users" = [ "search" ];
                  "mealie.users" = [ "mealie" ];
                  "minio.users" = [ "minio" ];
                  "llm.users" = [ "llm" ];
                  "books.users" = [ "books" ];
                  "adguard.users" = [ "adguard" ];
                  "git.users" = [ "git" ];
                  "prometheus.users" = [ "prometheus" ];
                  "grafana.users" = [ "grafana" ];
                  "grafana.guests" = [ "grafana" ];
                  "vpn.admins" = [ "vpn" ];
                  "dashboard.users" = [ "dashboard" ];
                  "webmail.users" = [ "webmail" ];
                };
              };
            };
          };

        };
      };
    };
    systemd.tmpfiles.rules = singleton "d /persist/var/lib/kanidm/backup 0700 kanidm kanidm -";
    modules.backup.restic = {
      enable = true;
      list = singleton {
        name = "kanidm";
        path = "/var/lib/kanidm/backup";
      };
    };
    arcanum.sysUsers = [ "kanidm" ];
    users.users.kanidm.extraGroups = [
      "acme"
      "caddy"
    ]; # for some reason caddy group owns the cert
  };
  persist.directories = singleton {
    directory = "/var/lib/kanidm";
    user = "kanidm";
    group = "kanidm";
    mode = "0700";
  };
}
