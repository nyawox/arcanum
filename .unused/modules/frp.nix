{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.services.frp;
in
{
  options = {
    modules.services.frp = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    services.frp = {
      enable = true;
      role = "server";
      settings = {
        common = {
          bind_port = 7034;
        };
      };
    };
    networking.firewall.allowedTCPPorts = [ 25565 ];
  };
}
