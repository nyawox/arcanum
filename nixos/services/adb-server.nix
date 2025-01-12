{
  lib,
  pkgs,
  arcanum,
  ...
}:
{
  content = {
    systemd.user.services.adb-server = {
      description = "ADB Server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "default.target" ];
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.android-tools}/bin/adb nodaemon server";
        Restart = "always";
        RestartSec = 1;
        PrivateTmp = true;
      };
    };
    programs.adb.enable = true;
    users.users."${arcanum.username}".extraGroups = lib.singleton "adbusers";
  };
  userPersist.directories = lib.singleton ".android";
}
