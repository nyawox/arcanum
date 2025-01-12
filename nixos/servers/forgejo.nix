# forgejo@hostname:user/repo.git
# after enabling this module the service may fail to start the first time
{
  cfg,
  config,
  pkgs,
  lib,
  arcanum,
  hostname,
  ...
}:
with lib;
let
  domain = "git.${arcanum.domain}";
  policy-json = pkgs.writeTextFile {
    name = "policy.json";
    text = ''
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "s3:ListBucket",
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject"
            ],
            "Resource": [
              "arn:aws:s3:::forgejo",
              "arn:aws:s3:::forgejo/*"
            ]
          }
        ]
      }
    '';
  };
  theme = pkgs.fetchzip {
    url = "https://github.com/catppuccin/gitea/releases/download/v1.0.1/catppuccin-gitea.tar.gz";
    hash = "sha256-et5luA3SI7iOcEIQ3CVIu0+eiLs8C/8mOitYlWQa/uI=";
    stripRoot = false;
  };
in
{
  options = {
    port = mkOption {
      type = types.int;
      default = 3145;
    };
    sshPort = mkOption {
      type = types.int;
      default = 3024;
    };
  };
  extraConfig = [
    (mkIf config.modules.servers.minio.enable {
      modules.servers.minio.buckets = [
        {
          name = "forgejo";
          policy = policy-json;
        }
      ];
    })
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-forgejo = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-forgejo.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc "SELECT 1 FROM pg_roles WHERE rolname='forgejo'" | grep -q 1 || $PSQL -tAc 'CREATE USER "forgejo"'
        $PSQL -tAc "SELECT 1 FROM pg_database WHERE datname = 'forgejo'" | grep -q 1 || $PSQL -tAc "CREATE DATABASE forgejo WITH OWNER forgejo TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8'"
        $PSQL -tAc 'ALTER ROLE "forgejo" WITH PASSWORD '"'$db_password'"
        $PSQL -tAc 'ALTER DATABASE "forgejo" OWNER TO "forgejo";'
      '';
    })
  ];
  content = {
    modules.networking.tailscale.tags = [ "tag:admin-git-server" ];
    sops.secrets = {
      forgejo-postgres = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-smtp-from = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-smtp-address = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-smtp-port = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-smtp-username = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-smtp-password = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-minio-id = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-minio-key = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
      forgejo-oauth-secret = {
        sopsFile = "${arcanum.secretPath}/forgejo-secrets.yaml";
        owner = config.services.forgejo.user;
        format = "yaml";
      };
    };
    services.forgejo = {
      enable = true;
      stateDir = "/var/lib/forgejo";
      database = {
        createDatabase = false;
        type = "postgres";
        host = "localpost.${arcanum.internal}";
        port = 5432;
        name = "forgejo";
        user = "forgejo";
        passwordFile = config.sops.secrets.forgejo-postgres.path;
      };
      lfs.enable = true;
      settings = {
        default.APP_NAME = "${arcanum.serviceName}Hub";
        server = {
          DOMAIN = domain;
          ROOT_URL = "https://${domain}";
          HTTP_PORT = cfg.port;
          START_SSH_SERVER = true;
          SSH_PORT = cfg.sshPort;
        };
        session = {
          COOKIE_SECURE = true;
          PROVIDER = "db";
        };
        security = {
          INSTALL_LOCK = true;
          DISABLE_GIT_HOOKS = false;
        };
        service = {
          REGISTER_EMAIL_CONFIRM = false;
          DISABLE_REGISTRATION = false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
          REQUIRE_SIGNIN_VIEW = false;
          ENABLE_NOTIFY_MAIL = true;
        };
        openid = {
          ENABLE_OPENID_SIGNIN = true;
          ENABLE_OPENID_SIGNUP = true;
          WHITELISTED_URIS = "account.${arcanum.domain}";
        };
        oauth2_client = {
          REGISTER_EMAIL_CONFIRM = false;
          ENABLE_AUTO_REGISTRATION = true;
          ACCOUNT_LINKING = "login";
          USERNAME = "nickname";
          UPDATE_AVATAR = true;
          OPENID_CONNECT_SCOPES = "openid email profile";
        };
        storage = {
          STORAGE_TYPE = "minio";
          MINIO_ENDPOINT = "localpost.${arcanum.internal}:9314";
          MINIO_BUCKET = "forgejo";
          MINIO_LOCATION = "us-east-1";
        };
        repository = {
          DEFAULT_PRIVATE = "private";
          DEFAULT_BRANCH = "main";
          ENABLE_PUSH_CREATE_USER = true;
          ENABLE_PUSH_CREATE_ORG = true;
        };
        mailer = {
          ENABLED = true;
          PROTOCOL = "STARTTLS";
        };
        actions.ENABLED = false;
        ui = {
          DEFAULT_THEME = "catppuccin-mocha-pink";
          THEMES = builtins.concatStringsSep "," (
            [ "auto" ]
            ++ (map (name: lib.removePrefix "theme-" (lib.removeSuffix ".css" name)) (
              builtins.attrNames (builtins.readDir theme)
            ))
          );
        };
      };
      secrets = {
        mailer = {
          FROM = config.sops.secrets.forgejo-smtp-from.path;
          SMTP_ADDR = config.sops.secrets.forgejo-smtp-address.path;
          SMTP_PORT = config.sops.secrets.forgejo-smtp-port.path;
          USER = config.sops.secrets.forgejo-smtp-username.path;
          PASSWD = config.sops.secrets.forgejo-smtp-password.path;
        };
        storage = {
          MINIO_ACCESS_KEY_ID = config.sops.secrets.forgejo-minio-id.path;
          MINIO_SECRET_ACCESS_KEY = config.sops.secrets.forgejo-minio-key.path;
        };
      };
    };

    arcanum.sysUsers = [ "forgejo" ];
    systemd.services.forgejo =
      let
        authConfig = {
          name = arcanum.domain;
          provider = "openidConnect";
          key = "forgejo";
          baseUrl = "https://account.${arcanum.domain}";
          groupClaimName = "groups";
          adminGroup = "admin";
        };

        oauthArgs = concatStringsSep " " [
          "--name ${authConfig.name}"
          "--provider ${authConfig.provider}"
          "--key ${authConfig.key}"
          "--secret $(cat ${config.sops.secrets.forgejo-oauth-secret.path})"
          "--auto-discover-url ${authConfig.baseUrl}/oauth2/openid/${authConfig.key}/.well-known/openid-configuration"
          "--group-claim-name ${authConfig.groupClaimName}"
          "--admin-group ${authConfig.adminGroup}"
        ];

        runForgejoAdmin = cmd: ''
          if [ ! -f "${config.sops.secrets.forgejo-oauth-secret.path}" ]; then
            echo "Error: OAuth secret file not found"
            exit 1
          fi

          ${getExe config.services.forgejo.package} admin ${cmd}
        '';
      in
      {
        # nix shell nixpkgs#forgejo
        # sudo -u forgejo gitea --config /var/lib/forgejo/custom/conf/app.ini admin auth list
        preStart =
          lib.mkAfter # bash
            ''
              set -e

              echo "Getting OAuth provider list..."
              oauth_list=$(${runForgejoAdmin "auth list"}) || {
                echo "Error: Failed to get OAuth provider list"
                exit 1
              }

              oauth_id="$(echo "$oauth_list" | ${getExe pkgs.gnugrep} -w "OAuth2" | cut -f1)"

              if ! echo "$oauth_list" | grep -q "${authConfig.name}"; then
                echo "Adding OAuth provider..."
                ${runForgejoAdmin "auth add-oauth ${oauthArgs}}"}
              else
                echo "Updating OAuth provider..."
                ${runForgejoAdmin "auth update-oauth --id $oauth_id ${oauthArgs}"}
              fi

              echo "Installing Catppuccin assets"
              rm -rf ${config.services.forgejo.stateDir}/custom/public/assets
              mkdir -p ${config.services.forgejo.stateDir}/custom/public/assets
              ln -sf ${theme} ${config.services.forgejo.stateDir}/custom/public/assets/css
            '';

        serviceConfig = {
          AmbientCapabilities = mkForce "CAP_NET_BIND_SERVICE";
          CapabilityBoundingSet = mkForce "CAP_NET_BIND_SERVICE";
          PrivateUsers = mkForce false;
        };
      };
  };
  persist.directories = singleton {
    directory = "/var/lib/forgejo";
    user = "forgejo";
    group = "forgejo";
    mode = "750";
  };
}
