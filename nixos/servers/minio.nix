{
  cfg,
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  mkBucket = bucket: {
    enable = true;
    path = with pkgs; [
      minio
      minio-client
    ];
    wantedBy = [ "multi-user.target" ];
    after = [ "minio.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "minio";
      Group = "minio";
      RuntimeDirectory = "minio-config";
      EnvironmentFile = [
        config.sops.secrets.minio-secrets.path
        config.sops.secrets."minio-${bucket.name}".path
      ];
    };
    script = ''
      set -e
      CONFIG_DIR=$RUNTIME_DIRECTORY
      mc --config-dir "$CONFIG_DIR" config host add minio http://localhost:9314 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"
      mc --config-dir "$CONFIG_DIR" admin user add minio "$CLIENT_ACCESS_KEY" "$CLIENT_SECRET_KEY"
      mc --config-dir "$CONFIG_DIR" admin policy create minio ${lib.strings.toUpper bucket.name}_POLICY "${bucket.policy}"
      mc --config-dir "$CONFIG_DIR" admin policy attach minio ${lib.strings.toUpper bucket.name}_POLICY --user "$CLIENT_ACCESS_KEY"
      mc --config-dir "$CONFIG_DIR" mb --ignore-existing minio/${bucket.name}
    '';
  };
  mkMinioSecrets = bucket: {
    "minio-${bucket.name}" = {
      sopsFile = "${arcanum.secretPath}/minio-${bucket.name}.yaml";
      format = "yaml";
    };
  };
in
{
  options.buckets = mkOption {
    type =
      with types;
      listOf (submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the bucket";
          };
          policy = mkOption {
            type = types.path;
            description = "Policy json";
          };
        };
      });
    default = [ ];
    description = "List of buckets with name and path.";
  };
  content = {
    services = {
      minio = {
        enable = true;
        browser = true;
        listenAddress = "0.0.0.0:9314";
        consoleAddress = "0.0.0.0:9315"; # web UI
        rootCredentialsFile = config.sops.secrets.minio-secrets.path;
      };
    };
    systemd.services =
      listToAttrs (map (bucket: nameValuePair "minio-${bucket.name}" (mkBucket bucket)) cfg.buckets)
      // {
        minio = {
          environment = {
            MINIO_BROWSER_REDIRECT_URL = "https://minio.${arcanum.domain}";
            MINIO_IDENTITY_OPENID_DISPLAY_NAME = "${arcanum.serviceName} Account";
            MINIO_IDENTITY_OPENID_CLIENT_ID = "minio";
            MINIO_IDENTITY_OPENID_CONFIG_URL = "https://account.${arcanum.domain}/oauth2/openid/minio/.well-known/openid-configuration";
            MINIO_IDENTITY_OPENID_SCOPES = "openid,profile,email";
            MINIO_PROMETHEUS_AUTH_TYPE = "public";
            MINIO_PROMETHEUS_URL = "http://localpost.${arcanum.internal}:9090/";
            MINIO_PROMETHEUS_JOB_ID = "minio-job";
          };
        };
      };
    sops.secrets =
      listToAttrs (
        concatMap (
          bucket: mapAttrsToList (name: value: nameValuePair name value) (mkMinioSecrets bucket)
        ) cfg.buckets
      )
      // {
        minio-secrets = {
          sopsFile = "${arcanum.secretPath}/minio-secrets.env";
          owner = "minio";
          group = "minio";
          format = "dotenv";
        };
      };
  };
  persist.directories = singleton {
    directory = "/var/lib/minio";
    user = "minio";
    group = "minio";
    mode = "750";
  };
}
