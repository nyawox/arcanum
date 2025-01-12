{
  config,
  lib,
  arcanum,
  hostname,
  ...
}:
with lib;
{
  extraConfig = [
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-mealie = {
        sopsFile = "${arcanum.secretPath}/mealie-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "mealie" ];
        ensureUsers = singleton {
          name = "mealie";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-mealie.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "mealie" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  homeConfig.services.podman.containers."mealie" = {
    image = "ghcr.io/mealie-recipes/mealie:nightly";
    autoStart = true;
    autoUpdate = "registry";
    volumes = [ "/var/lib/mealie:/app/data" ];
    environmentFile = [ config.sops.secrets.mealie-env.path ];
    environment = {
      # Since i run in rootless podman there is no need to change to dedicated mealie user
      PUID = 0;
      PGID = 0;
      ALLOW_SIGNUP = "False";
      BASE_URL = "https://recipes.${arcanum.domain}";
      DB_ENGINE = "postgres";
      POSTGRES_USER = "mealie";
      POSTGRES_SERVER = "localpost.${arcanum.internal}";
      POSTGRES_PORT = "5432";
      POSTGRES_DB = "mealie";
      OIDC_AUTH_ENABLED = "True";
      OIDC_AUTO_REDIRECT = "True";
      OIDC_SIGNUP_ENABLED = "True";
      OIDC_PROVIDER_NAME = "${arcanum.serviceName} Account";
      OIDC_USER_CLAIM = "preferred_username";
      OIDC_CONFIGURATION_URL = "https://account.${arcanum.domain}/oauth2/openid/mealie/.well-known/openid-configuration";
      OIDC_ADMIN_GROUP = "admin";
      OIDC_USER_GROUP = "user";
      OIDC_CLIENT_ID = "mealie";
    };
    network = singleton "shared";
    networkAlias = singleton "mealie";
    ports = singleton "8949:9000";
  };

  content = {
    modules.virtualisation.podman.enable = mkForce true;
    sops.secrets.mealie-env = {
      sopsFile = "${arcanum.secretPath}/mealie-secrets.yaml";
      owner = arcanum.username;
      group = "users";
      format = "yaml";
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/mealie";
    user = arcanum.username;
    group = "users";
    mode = "750";
  };
}
