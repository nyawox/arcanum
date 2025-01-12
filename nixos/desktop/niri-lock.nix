{
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
{
  content = {
    systemd.user.services.systemd-lockscreen =
      let
        script = pkgs.writeScriptBin "lock-screen.sh" ''
          #!/usr/bin/env bash
          ${getExe pkgs.niri-unstable} msg action do-screen-transition --delay-ms 1000
          # hardcoded DP-4 is fine for now
          ${getExe pkgs.gtklock} -d --monitor-priority DP-4 -c /etc/gtklock.ini
        '';
      in
      {
        path = [ pkgs.bash ];
        description = "Lockscreen";
        onSuccess = [ "unlock.target" ];
        partOf = [ "lock.target" ];
        before = [ "lock.target" ];
        wantedBy = [ "lock.target" ];
        serviceConfig = {
          Type = "forking";
          ExecStart = "${getExe script}";
          Restart = "on-failure";
          RestartSec = 0;
        };
      };
    security.pam.services.gtklock = { };
    services.accounts-daemon.enable = true;
    environment.etc."gtklock.ini".text =
      let
        modules = concatStringsSep ";" [
          "${pkgs.gtklock-userinfo-module}/lib/gtklock/userinfo-module.so"
          "${pkgs.gtklock-powerbar-module}/lib/gtklock/powerbar-module.so"
          "${pkgs.gtklock-playerctl-module}/lib/gtklock/playerctl-module.so"
        ];
      in
      # ini
      ''
        [main]
        gtk-theme=${arcanum.homeCfg.gtk.theme.name}
        modules=${modules}
        [powerbar]
        logout-command=${getExe pkgs.niri-unstable} msg action quit --skip-confirmation
        show-labels=false
        linked-buttons=false
        [userinfo]
        round-image=true
      '';
    services.systemd-lock-handler.enable = true;
  };
  homeConfig = {
    home.file.".face".source = pkgs.fetchurl {
      url = "https://i.imgur.com/GIiXGUW.png";
      sha256 = "1kys99i4zpn9akilk7sd5l4wmay1q5fxy543zp04qfp4f5cza2jh";
    };
    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 250;
          command = "${getExe pkgs.niri-unstable} msg action power-off-monitors";
        }
        {
          timeout = 300;
          command = "${pkgs.systemd}/bin/loginctl lock-session";
        }
      ];
    };
    systemd.user.services.swayidle.Unit.WantedBy = "niri.service";
  };
}
