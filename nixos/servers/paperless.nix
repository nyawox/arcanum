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
    (mkIf config.modules.servers.redis.enable {
      services.redis.servers.paperless = {
        enable = true;
        openFirewall = false;
        logLevel = "debug";
      };
      environment.persistence."/persist".directories = singleton {
        directory = "/var/lib/redis-paperless";
        user = "redis-paperless";
        group = "redis-paperless";
        mode = "750";
      };
    })
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-paperless = {
        sopsFile = "${arcanum.secretPath}/paperless-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "paperless" ];
        ensureUsers = singleton {
          name = "paperless";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-paperless.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "paperless" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  content = {
    sops = {
      secrets = {
        paperless-env = {
          sopsFile = "${arcanum.secretPath}/paperless-secrets.yaml";
          owner = config.services.paperless.user;
          group = config.services.paperless.user;
          format = "yaml";
          restartUnits = [
            "paperless-consumer.service"
            "paperless-scheduler.service"
            "paperless-task-queue.service"
            "paperless-web.service"
          ];
        };
        paperless-user-id = {
          sopsFile = "${arcanum.secretPath}/paperless-secrets.yaml";
          owner = config.services.paperless.user;
          group = config.services.paperless.user;
          format = "yaml";
          restartUnits = [
            "paperless-consumer.service"
            "paperless-scheduler.service"
            "paperless-task-queue.service"
            "paperless-web.service"
          ];
        };
      };
      templates."paperless-notification.sh" = {
        owner = config.services.paperless.user;
        group = config.services.paperless.user;
        mode = "0700";
        restartUnits = [
          "paperless-consumer.service"
          "paperless-scheduler.service"
          "paperless-task-queue.service"
          "paperless-web.service"
        ];
        content = ''
          #!${getExe pkgs.bash}
          ${getExe pkgs.curl} --request POST --url https://push.paperparrot.me/ --header 'Content-Type: application/json' --data '{
            "user_id": "${config.sops.placeholder.paperless-user-id}",
            "document_id": "''${DOCUMENT_ID}"
          }'
        '';
      };
    };
    services.paperless = {
      enable = true;
      package = pkgs.paperless-ngx.overrideAttrs (old: {
        # as an enduser i don't wanna jump through hoops just to tests break again in the next update
        doInstallCheck = false;
        patches = (old.patches or [ ]) ++ [
          # oidc is mostly unusable without this feature
          # https://github.com/paperless-ngx/paperless-ngx/discussions/7307#discussion-6972082
          # https://github.com/paperless-ngx/paperless-ngx/pull/7655
          ./paperless-oidc.patch
        ];
      });
      address = "0.0.0.0";
      port = 28198;
      user = "paperless";
      environmentFile = config.sops.secrets.paperless-env.path;
      settings = {
        PAPERLESS_DBENGINE = "postgresql";
        PAPERLESS_DBHOST = "localpost.${arcanum.internal}";
        PAPERLESS_DBPORT = 5432;
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        PAPERLESS_CONSUMER_RECURSIVE = "true";
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = "true";
        PAPERLESS_OCR_LANGUAGE = "eng+jpn+por";
        PAPERLESS_OCR_LANGUAGES = "jpn por"; # additional languages to install
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
          jpeg_quality = 100;
          invalidate_digital_signatures = true;
        };
        PAPERLESS_OCR_OUTPUT_TYPE = "pdfa-3";
        PAPERLESS_URL = "https://docs.${arcanum.domain}";
        PAPERLESS_USE_X_FORWARD_HOST = true;
        PAPERLESS_USE_X_FORWARD_PORT = true;
        PAPERLESS_THREADS_PER_WORKER = 1; # 3 threads is too much for this little boi
        PAPERLESS_CONVERT_MEMORY_LIMIT = "1gb";
        PAPERLESS_POST_CONSUME_SCRIPT = "${config.sops.templates."paperless-notification.sh".path}";
      };
    };
    systemd = {
      tmpfiles.rules = [
        "d /var/lib/paperless/consume 0750 paperless paperless -"
        "d /var/lib/paperless/media 0750 paperless paperless -"
      ];
      services = {
        paperless-scheduler.serviceConfig.PrivateNetwork = mkForce false; # breaks postgresql connectivity and some scripts
        paperless-consumer.serviceConfig.PrivateNetwork = mkForce false;
        paperless-web.serviceConfig.PrivateNetwork = mkForce false;
      };
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/paperless";
    user = "paperless";
    group = "paperless";
    mode = "750";
  };
}
