{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.cosmic;
in
{
  imports = [ inputs.nixos-cosmic.nixosModules.default ];
  options = {
    modules.desktop.cosmic = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = mkIf cfg.enable {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
    environment.cosmic.excludePackages = with pkgs; [
      fira
      gnome.adwaita-icon-theme
      hicolor-icon-theme
    ];

    # Handle keyboard media keys
    sound.mediaKeys.enable = true;

    environment.persistence."/persist".users.${username} = {
      directories = [
        ".local/share/nwg-look"
        ".config/cosmic"
      ];
      files = [ ".config/xsettingsd/xsettingsd.conf" ];
    };
  };
}
