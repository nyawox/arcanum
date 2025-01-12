{
  cfg,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options = {
    ip = mkOption {
      type = types.str;
      default = "localcast";
    };
    launcher = mkOption {
      type = types.str;
      default = "com.spocky.projengmenu/.ui.home.MainActivity";
    };
  };
  content = {
    modules.networking.tailscale.tags = [ "tag:admin-firetv-access" ];
    modules.services.adb-server.enable = mkForce true;
    systemd.user.services.firetv-launcher = {
      description = "Override Amazon Home Screen";
      after = [
        "network-online.target"
        "adb-server.service"
      ];
      wants = [
        "network-online.target"
        "adb-server.service"
      ];
      wantedBy = [ "default.target" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.android-tools}/bin/adb connect ${cfg.ip}";
        ExecStart =
          # bash
          ''
            ${getExe pkgs.bash} -c "${pkgs.android-tools}/bin/adb -s ${cfg.ip} logcat -T 1 '*:I' | ${getExe pkgs.gnugrep} --line-buffered 'com.amazon.tv.launcher/.ui.HomeActivity_vNext' | ${pkgs.findutils}/bin/xargs -I {} ${pkgs.android-tools}/bin/adb -s ${cfg.ip} shell am start -n ${cfg.launcher}"
          '';
        Restart = "always";
        RestartSec = 5;
        PrivateTmp = true;
      };
    };
  };
}
