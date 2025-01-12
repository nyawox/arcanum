# disabled and migrated to pushover
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.services.ntfy-sh;
in
{
  options = {
    modules.services.ntfy-sh = {
      enable = mkEnableOption "ntfy-sh";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets.ntfy-env = {
      sopsFile = ../../../secrets/ntfy.env;
      format = "dotenv";
    };
    sops.secrets.ntfy-pushenv = {
      sopsFile = ../../../secrets/ntfy-push.env;
      format = "dotenv";
    };
    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = ":2521";
        base-url = "https://ntfy.${arcanum.domain}";
        upstream-base-url = "https://ntfy.sh"; # required to send ios app push notification https://docs.ntfy.sh/known-issues/
        auth-default-access = "deny-all";
        web-push-file = "/var/lib/ntfy-sh/webpush.db";
        web-push-email-address = "lodging.halberd2n@icloud.com";
      };
    };
    # web push secrets
    systemd.services.ntfy-sh.serviceConfig.EnvironmentFile = config.sops.secrets.ntfy-pushenv.path;
    # add users
    systemd.services.ntfy-setup-users = {
      enable = true;
      description = "Automatically add ntfy-sh users";
      wants = [
        "network-online.target"
        "ntfy-sh.service"
      ];
      after = [
        "network-online.target"
        "ntfy-sh.service"
        "var-lib-private-ntfy\\x2dsh.mount"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.ntfy-sh ];
      script = ''
        # `ntfy user list` command outputs to stderr
        # 2>&1 redirects stderr into stdout
        if ! ntfy user list 2>&1 | grep -q "user ''${NTFY_WRITEUSER}"; then
          NTFY_PASSWORD=$NTFY_WRITEPASS ntfy user add ''${NTFY_WRITEUSER}
          ntfy access ''${NTFY_WRITEUSER} '*' write-only
        fi
        if ! ntfy user list 2>&1 | grep -q "user ''${NTFY_READUSER}"; then
          NTFY_PASSWORD=$NTFY_READPASS ${getExe' pkgs.ntfy-sh "ntfy"} user add ''${NTFY_READUSER}
          ntfy access ''${NTFY_READUSER} '*' read-only
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.secrets.ntfy-env.path;
        ReadOnlyPaths = "/nix/store";
        ReadWritePaths = [
          "/var/lib/private/ntfy-sh"
        ];
        ProtectSystem = "strict";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
    environment.persistence."/persist".directories =
      mkIf config.modules.sysconf.impermanence.enable
        (singleton {
          directory = "/var/lib/private/ntfy-sh";
          user = "ntfy-sh";
          group = "ntfy-sh";
          mode = "750";
        });
  };
}
