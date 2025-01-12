{
  lib,
  pkgs,
  ...
}:
with lib;
{
  homeConfig = {
    home.packages = with pkgs; [
      swaynotificationcenter
      nerd-fonts.ubuntu
    ];
    xdg.configFile."swaync/style.css".source = pkgs.fetchurl {
      url = "https://github.com/catppuccin/swaync/releases/download/v0.1.2.1/mocha.css";
      sha256 = "19z41gvds15av1wpidzli1yqbm70fmdv04blr23ysbl944jvfvnv";
    };
  };
}
