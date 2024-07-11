{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.sddm;
in {
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
      extraPackages = [inputs.latest.legacyPackages.${pkgs.system}.sddm-astronaut];
      wayland.enable = true;
    };
  };
}
