{
  lib,
  pkgs,
  ...
}:
with lib;
{
  homeConfig = {
    home.packages = with pkgs; [
      xwayland
      xwayland-satellite-unstable
    ];
    programs.niri.settings = {
      spawn-at-startup = [
        {
          command = [
            "${getExe pkgs.xwayland-satellite-unstable}"
            ":25"
          ];
        }
      ];
      environment = {
        DISPLAY = ":25";
      };
    };
  };
}
