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
      sops.secrets.postgres-atuin = {
        sopsFile = "${arcanum.secretPath}/atuin-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "atuin" ];
        ensureUsers = singleton {
          name = "atuin";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-atuin.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "atuin" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  content = {
    arcanum.sysUsers = [ "atuin" ];
    sops.secrets.atuin-env = {
      sopsFile = "${arcanum.secretPath}/atuin-secrets.yaml";
      owner = "atuin";
      group = "atuin";
      format = "yaml";
    };
    systemd.services.atuin.serviceConfig.EnvironmentFile = config.sops.secrets.atuin-env.path;
    services.atuin = {
      enable = true;
      port = 8878;
      database = {
        createLocally = false;
        uri = null; # set ATUIN_DB_URI through an EnvironmentFile
      };
      openRegistration = true;
    };
  };
}
