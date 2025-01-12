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
  mkResticBackup = backup: {
    initialize = true;
    paths = [ backup.path ];
    exclude = [ ".restic-init-done" ];
    passwordFile = config.sops.secrets."restic-${backup.name}-pw".path;
    environmentFile = config.sops.secrets."restic-${backup.name}-env".path;
    repository = "b2:${backup.name}-nyaa";
    backupPrepareCommand = ''
      echo "Notifying healthchecks the start of the backup process"
      ${getExe pkgs.curl} -m 10 --retry 5 "https://health.${arcanum.domain}/ping/''${HC}/start"
    '';
    # TODO: Handle failure
    backupCleanupCommand = ''
      echo "Notifying healthchecks the finish of the backup process"
      ${getExe pkgs.curl} -m 10 --retry 5 "https://health.${arcanum.domain}/ping/''${HC}"
    '';
    timerConfig = {
      OnCalendar = "*-*-* 14:05:00 UTC";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
    pruneOpts =
      backup.customOpts or [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-yearly 10"
      ];
  };

  mkRestoreService = backup: {
    enable = true;
    description = "Automatically restore backups";
    path = [ pkgs.restic ];
    restartIfChanged = false;
    environment = {
      inherit (config.systemd.services."restic-backups-${backup.name}".environment)
        RESTIC_CACHE_DIR
        RESTIC_PASSWORD_FILE
        RESTIC_REPOSITORY
        RESTIC_REPOSITORY_FILE
        ;
    };
    serviceConfig = {
      Type = "oneshot";
      inherit (config.systemd.services."restic-backups-${backup.name}".serviceConfig) EnvironmentFile;
    };
    script = ''
      ${optionalString (!backup.pgsql) # bash
        ''
          if [[ ! -f ${backup.path}/.restic-init-done ]]; then
            if ! restic cat config >/dev/null 2>&1; then
                echo "Repository does not exist. Initializing..."
                restic init
                touch ${backup.path}/.restic-init-done
                exit 0
            fi
            restic restore latest:${backup.path} --target ${backup.path}
            touch ${backup.path}/.restic-init-done | true
          fi
        ''
      }
      ${optionalString backup.pgsql # bash
        ''
          if [[ ! -f ${backup.path}/.restic-init-done ]]; then
            if ! restic cat config >/dev/null 2>&1; then
                echo "Repository does not exist. Initializing..."
                restic init
                touch ${backup.path}/.restic-init-done
                exit 0
            fi
            mkdir -p ${backup.path}/.restore
            restic restore latest:${backup.path} --target ${backup.path}/.restore
            ${getExe pkgs.zstd} -d --stdout ${backup.path}/.restore/all.sql.zstd > ${backup.path}/.restore/all.sql
            ${getExe' pkgs.sudo-rs "sudo"} -u postgres ${getExe' pkgs.postgresql "psql"} -f ${backup.path}/.restore/all.sql postgres
            rm -rf ${backup.path}/.restore | true
            touch ${backup.path}/.restic-init-done | true
          fi
        ''
      }
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  # fix messed up uid:gid after restoration
  mkPermission = backup: {
    "${backup.path}/*".Z = {
      user = if (backup.user != null) then backup.user else backup.name;
      group = if (backup.group != null) then backup.group else backup.name;
    };
  };

  mkResticSecrets = backup: {
    "restic-${backup.name}-pw" = {
      sopsFile = "${arcanum.secretPath}/restic-${backup.name}.psk";
      format = "binary";
    };
    "restic-${backup.name}-env" = {
      sopsFile = "${arcanum.secretPath}/restic-${backup.name}.env";
      format = "dotenv";
    };
  };
in
{
  options.list = mkOption {
    type =
      with types;
      listOf (submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the backup configuration";
          };
          path = mkOption {
            type = types.str;
            description = "Path to backup";
          };
          pgsql = mkOption {
            type = types.bool;
            default = false;
            description = "Enable this for postgresql. I was too lazy to make the module more flexible";
          };
          user = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          group = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          customOpts = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
        };
      });
    default = [ ];
    description = "List of restic backup configurations with name and path.";
  };

  content = {
    services.restic.backups = listToAttrs (
      map (backup: nameValuePair backup.name (mkResticBackup backup)) cfg.list
    );

    systemd = {
      services = listToAttrs (
        map (backup: nameValuePair "restic-restore-${backup.name}" (mkRestoreService backup)) cfg.list
      );
      tmpfiles.settings = listToAttrs (
        map (backup: nameValuePair "fix-${backup.name}-permission" (mkPermission backup)) cfg.list
      );
    };

    sops.secrets = listToAttrs (
      concatMap (
        backup: mapAttrsToList (name: value: nameValuePair name value) (mkResticSecrets backup)
      ) cfg.list
    );

    services.postgresqlBackup = mkIf (any (backup: backup.pgsql) cfg.list) {
      enable = true;
      backupAll = true;
      compression = "zstd";
      compressionLevel = 16;
      location = "/var/backup/postgresql";
    };
  };
  persist.directories = mkIf (any (backup: backup.pgsql) cfg.list) (
    singleton "/var/backup/postgresql"
  );
}
