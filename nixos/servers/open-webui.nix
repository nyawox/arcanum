{
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
    default = 11454;
  };
  extraConfig = [
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localhoax") {
      sops.secrets.postgres-open-webui = {
        sopsFile = "${arcanum.secretPath}/open-webui-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "open-webui" ];
        ensureUsers = singleton {
          name = "open-webui";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-open-webui.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "open-webui" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  homeConfig.services.podman.containers."open-webui" = {
    image = "ghcr.io/open-webui/open-webui:main";
    autoStart = true;
    autoUpdate = "registry";
    volumes = [ "/var/lib/open-webui:/app/backend/data" ];
    environmentFile = [ config.sops.secrets.open-webui-secrets.path ];
    environment = {
      ENV = "prod";
      WEBUI_URL = "https://llm.${arcanum.domain}";
      OLLAMA_BASE_URL = "http://lolcathost.${arcanum.internal}:11434";
      ENABLE_RAG_WEB_SEARCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      SEARXNG_QUERY_URL = "http://lokalhost.${arcanum.internal}:8420/search";
      RAG_WEB_SEARCH_RESULT_COUNT = "5";
      AUDIO_STT_ENGINE = "openai";
      AUDIO_STT_MODEL = "whisper-large-v3";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      ENABLE_SIGNUP = "False";
      ENABLE_LOGIN_FORM = "True";
      ENABLE_OAUTH_SIGNUP = "True";
      OAUTH_PROVIDER_NAME = "${arcanum.serviceName} Account";
      OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "True";
      ENABLE_OAUTH_ROLE_MANAGEMENT = "True";
      OAUTH_ROLES_CLAIM = "llm_roles";
      OAUTH_ALLOWED_ROLES = "user,admin";
      OAUTH_ADMIN_ROLES = "admin";
      OAUTH_CLIENT_ID = "llm";
      OPENID_PROVIDER_URL = "https://account.${arcanum.domain}/oauth2/openid/llm/.well-known/openid-configuration";
      OPENID_REDIRECT_URI = "https://llm.${arcanum.domain}/oauth/oidc/callback";
      WEBUI_DEFAULT_USER_ROLE = "user";
    };
    network = singleton "shared";
    networkAlias = singleton "open-webui";
    ports = singleton "11454:8080";
  };
  content = {
    modules.virtualisation.podman.enable = mkForce true;
    sops.secrets.open-webui-secrets = {
      sopsFile = "${arcanum.secretPath}/open-webui-secrets.yaml";
      owner = arcanum.username;
      group = "users";
      format = "yaml";
    };
    systemd.tmpfiles.settings."open-webui"."/var/lib/open-webui".Z = {
      mode = "0750";
      user = arcanum.username;
      group = "users";
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/open-webui";
    user = arcanum.username;
    group = "users";
    mode = "750";
  };
}
