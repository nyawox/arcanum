{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.services.influxdb;
in
{
  options = {
    modules.services.influxdb = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    services.influxdb = {
      enable = true;
      extraConfig = {
        http = {
          log-enabled = false;
          bind-address = ":8234";
        };
      };
    };

    environment.persistence."/persist".directories =
      mkIf config.modules.sysconf.impermanence.enable
        (singleton {
          directory = "/var/db/influxdb";
          user = "influxdb";
          group = "influxdb";
        });
  };
}
