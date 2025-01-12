{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.services.moonshine;
in
{
  options = {
    modules.services.moonshine = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.moonshine ];
    systemd.user.services.moonshine = {
      enable = true;
      description = "Streaming server using the NVIDIA GameStream / Moonlight protocol.";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = "${getExe pkgs.moonshine} /home/${username}/.config/moonshine/config.toml";
      };
    };
    # networking.firewall = {
    #   allowedTCPPorts = [
    #     47984
    #     47989
    #     47990
    #     48010
    #   ];
    #   allowedUDPPorts = [
    #     47998
    #     47999
    #     48000
    #     48002
    #   ];
    # };
    environment.persistence."/persist".users.${username} = {
      directories = [ ".config/moonshine" ];
    };
  };
}
