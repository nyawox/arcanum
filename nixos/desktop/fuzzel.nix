{
  lib,
  pkgs,
  ...
}:
with lib;
{
  homeConfig = {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = "${getExe pkgs.foot}";
          font = mkForce "SFProDisplay:size=16";
          layer = "overlay";
        };
        colors = {
          background = "1e1e2efa"; # 0.95 opacity
          text = "cdd6f4ff";
          match = "f38ba8ff";
          selection = "585b70ff";
          selection-match = "f38ba8ff";
          selection-text = "cdd6f4ff";
          border = "b4befeff";
        };
      };
    };
  };
}
