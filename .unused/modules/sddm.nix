{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.sddm;
in
{
  options = {
    modules.desktop.sddm = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      package = pkgs.kdePackages.sddm; # pkgs.plasma5Packages.sddm doesn't work with qt6 theme
      theme = "sddm-astronaut-theme";
      extraPackages = [ pkgs.sddm-astronaut ];
      wayland.enable = true;
    };
    # You need to globally install it because the sddm module sets the ThemeDir to `/run/current-system/sw/share/sddm/themes`
    # Packages in `sddm.extraPackages` won't end up there.
    environment.systemPackages = [ pkgs.sddm-astronaut ];
  };
}
