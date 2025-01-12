{
  lib,
  config,
  osConfig,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.cosmic;
in
{
  options = {
    modules.desktop.cosmic = {
      enable = mkOption {
        type = types.bool;
        default = if osConfig.modules.desktop.cosmic.enable then true else false;
      };
    };
  };
  config = mkIf cfg.enable {
    home.sessionVariables = {
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1"; # Disables window decorations on Qt applications
      GTK_THEME = config.gtk.theme.name;
    };
    xdg.configFile."cosmic-comp.ron".source = ./cosmic-comp.ron;
  };
}
