{
  cfg,
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
{
  options.framerate = mkOption {
    type = types.int;
    default = 60;
  };
  content = {
    systemd.user.services.airplay = {
      enable = true;
      description = "AirPlay";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ]; # this must be set to ensure the service to only be valid whilst the session is active
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      serviceConfig = {
        # without unbuffer the logs are only printed when stopping service
        ExecStart = "${pkgs.expect}/bin/unbuffer ${getExe pkgs.uxplay} -n ${config.networking.hostName} -reg /home/${arcanum.username}/.config/.uxplay.register -fps ${builtins.toString cfg.framerate}";
        Environment = "UXPLAYRC=/etc/uxplayrc";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
    networking.firewall.allowedTCPPorts = [
      15244
      15245
      15246
    ];
    networking.firewall.allowedUDPPorts = [
      5353 # mDNS queries
      15244
      15245
      15246
    ];
    environment = {
      systemPackages = singleton pkgs.uxplay;
      etc."uxplayrc".text =
        # conf
        ''
          p 15244
          nh
          pin
          fs
        '';
    };
  };
  userPersist.files = singleton ".config/.uxplay.register";
  homeConfig.programs.nushell.shellAliases.airplay = "journalctl --user -xfeu airplay.service";
}
