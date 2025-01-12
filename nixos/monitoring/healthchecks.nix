{
  cfg,
  config,
  lib,
  arcanum,
  hostname,
  ...
}:
with lib;
{
  options.port = mkOption {
    type = types.int;
    default = 8451;
  };
  extraConfig = [
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-healthchecks = {
        sopsFile = "${arcanum.secretPath}/healthchecks-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "healthchecks" ];
        ensureUsers = singleton {
          name = "healthchecks";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-healthchecks.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "healthchecks" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  content = {
    sops.secrets = {
      "healthchecks-key" = {
        sopsFile = "${arcanum.secretPath}/healthchecks-secrets.yaml";
        owner = "healthchecks";
        group = "healthchecks";
        format = "yaml";
        restartUnits = [ "healthchecks.service" ];
      };
      "healthchecks-env" = {
        sopsFile = "${arcanum.secretPath}/healthchecks-secrets.yaml";
        owner = "healthchecks";
        group = "healthchecks";
        format = "yaml";
        restartUnits = [ "healthchecks.service" ];
      };
    };
    services.healthchecks = {
      enable = true;
      listenAddress = "0.0.0.0";
      inherit (cfg) port;
      settings = {
        SITE_NAME = "${arcanum.serviceName}Checks";
        SITE_ROOT = "https://health.${arcanum.domain}";
        SITE_LOGO_URL = "https://cdn.discordapp.com/emojis/1213684885483556864.webp";
        ALLOWED_HOSTS = [ "health.${arcanum.domain}" ];
        SECURE_PROXY_SSL_HEADER = "HTTP_X_FORWARDED_PROTO,https";
        RP_ID = "health.${arcanum.domain}"; # WebAuthn
        SECRET_KEY_FILE = config.sops.secrets.healthchecks-key.path;
        DB = "postgres";
        DB_NAME = "healthchecks";
        DB_USER = "healthchecks";
        DB_HOST = "localpost.${arcanum.internal}";
        DB_PORT = "5432";
        INTEGRATIONS_ALLOW_PRIVATE_IPS = "True";
        REGISTRATION_OPEN = false;
        # DEBUG = true;
      };
      settingsFile = config.sops.secrets.healthchecks-env.path;
    };
    modules.backup.restic = {
      enable = true;
      list = [
        {
          name = "healthchecks";
          path = config.services.healthchecks.dataDir;
        }
      ];
    };
  };
  persist.directories = singleton {
    directory = config.services.healthchecks.dataDir;
    inherit (config.services.healthchecks) user group;
    mode = "0700";
  };
}
