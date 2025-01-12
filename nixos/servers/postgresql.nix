{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
with lib;
let
  dataDir = "/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";
  # auto upgrade https://github.com/NixOS/nixpkgs/pull/327966
  pgsqlPkg =
    let
      basePkg =
        if config.services.postgresql.enableJIT then
          config.services.postgresql.package.withJIT
        else
          config.services.postgresql.package.withoutJIT;
    in
    if config.services.postgresql.extensions == [ ] then
      basePkg
    else
      basePkg.withPackages config.services.postgresql.extensions;
  upgradeScript =
    let
      args = {
        old-bindir = "/var/lib/postgresql/current/nix-postgresql-bin";
        old-datadir = "/var/lib/postgresql/current";
        new-datadir = dataDir;
      };
    in
    pkgs.writeShellApplication {
      name = "upgrade.sh";
      text = ''
        if ! [[ -e "/var/lib/postgresql/current" ]]; then
          echo "No old data found, assuming fresh deployment"
          exit 0
        fi

        if [[ "$(cat "/var/lib/postgresql/current/PG_VERSION")" == "${pgsqlPkg.psqlSchema}" ]]; then
          echo "Previous major version matches the current one. No upgrade necessary"
          exit 0
        fi

        pushd "${dataDir}"
        ${pgsqlPkg}/bin/pg_upgrade ${cli.toGNUCommandLineShell { } args}
        touch .post_upgrade
      '';
    };
  # Script to fix collation version mismatch issue
  # This usually happen on system update (when glibc get updated)
  reindexScript = pkgs.writeShellApplication {
    name = "pg_reindex";
    text = ''
      databases=$(sudo -u postgres psql -q -t -c "SELECT datname FROM pg_database")

      for database in $databases; do
          echo "Refreshing collation version for database: $database"
          sudo -u postgres psql -d "$database" -c "REINDEX DATABASE $database"
          sudo -u postgres psql -d "$database" -c "ALTER DATABASE $database REFRESH COLLATION VERSION"
      done
    '';
  };
  watchColVer = pkgs.writeShellApplication {
    name = "watch_colver_mismatch.sh";
    text = ''
      # Monitor journal logs for PostgreSQL collation version mismatch errors
      journalctl -u postgresql.service -f | while read -r line; do
          if echo "$line" | grep -q "collation version mismatch"; then
              # Stop PostgreSQL service
              systemctl stop postgresql.service

              # Reindex databases
              ${getExe reindexScript}

              # Restart PostgreSQL service
              systemctl start postgresql.service
          fi
      done
    '';
  };
in
{
  content = {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_17;
        enableTCPIP = true;
        settings.port = 5432;
        # local authentication is only left for postgres user
        authentication = mkForce ''
          local all      postgres               peer
          host  sameuser all      10.100.0.0/24 scram-sha-256
        '';
      };
    };
    modules.backup.restic = {
      enable = true;
      list = [
        {
          name = "postgresql-${hostname}";
          path = "/var/backup/postgresql";
          user = "postgresql";
          group = "postgresql";
          pgsql = true;
        }
      ];
    };
    environment.systemPackages = [ reindexScript ];

    systemd.services.postgresql.serviceConfig = {
      ExecStartPre =
        let
          upgrade = pkgs.writeShellApplication {
            name = "gradingUpping.sh";
            text = # bash
              ''
                ${getExe upgradeScript}
                if test -e "${dataDir}/.post_upgrade"; then # upgradeScript creates this file after successful upgrade
                  rm "${dataDir}/.first_startup" # don't execute initialScript after upgrade (see postStart in nixpkgs module)
                fi
                ln -sfn "${pgsqlPkg}/bin" "${dataDir}/nix-postgresql-bin"
                if [[ -d "/var/lib/postgresql" ]]; then
                  ln -sfn "${dataDir}" "/var/lib/postgresql/current"
                fi
              '';
          };
        in
        mkAfter [
          "${getExe upgrade}"
        ];
      ExecStartPost =
        let
          postUpgrade = pkgs.writeShellApplication {
            name = "postingGrade.sh";
            text = # bash
              ''
                if test -e "${dataDir}/.post_upgrade"; then
                  vacuumdb --port=${toString config.services.postgresql.settings.port} --all --analyze-in-stages
                  rm -f "${dataDir}/.post_upgrade"
                  rm -f "${dataDir}/delete_old_cluster.sh" # this scripts is useless here because it deletes /var/lib/postgresql/current symlink
                fi
              '';
          };
        in
        mkAfter [
          "${getExe postUpgrade}"
        ];
    };
    system.activationScripts.detect-previous-postgresql-installation = {
      deps = [ "etc" ];
      text = # bash
        ''
          previousPgDetect() {
            echo "Detecting previous PostgreSQL installation..."
            local env="$(/run/current-system/sw/bin/systemctl show postgresql.service --property=Environment --value || true)"
            if [[ -z "$env" ]]; then
              echo "Cannot load old PostgreSQL environment"
              return
            fi

            local oldDataDir="$(export $env; echo "''${PGDATA:-}")"
            local oldBinDir=$(export $env; dirname $(command -v postgres))

            if [[ -z "$oldDataDir" || -z "$oldBinDir" ]]; then
              echo "Could not detect old PostgreSQL installation"
              return
            fi

            echo "Detected old PostgreSQL installation!"
            echo "Setting old dataDir to '$oldDataDir'"
            echo "Setting old binDir to '$oldBinDir'"

            ln -sn "$oldDataDir" "/var/lib/postgresql/current"
            ln -sn "$oldBinDir" "/var/lib/postgresql/current/nix-postgresql-bin"
          }

          if [[ ! -e "/var/lib/postgresql/current" ]]; then
            previousPgDetect
          fi
        '';
    };
    # not tested
    systemd.services.pgsql-colver-watcher = {
      enable = true;
      restartIfChanged = false;
      description = "Watch PostgreSQL logs for collation version mismatch errors and fix automatically";
      after = [ "postgresql.service" ];
      wants = [ "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      script = "${getExe watchColVer}";

      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        ReadOnlyPaths = "/nix/store";
        ProtectSystem = "strict";
        PrivateTmp = true;
      };
    };
    services.prometheus.exporters.postgres = {
      enable = true;
      listenAddress = "0.0.0.0";
      port = 9187;
      runAsLocalSuperUser = true;
    };
  };
  persist.directories = singleton "/var/lib/postgresql";
}
