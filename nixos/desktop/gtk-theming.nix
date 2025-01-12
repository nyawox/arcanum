{
  lib,
  pkgs,
  ...
}:
with lib;
{
  homeConfig = {
    gtk = {
      enable = true;
      theme = mkForce {
        name = "catppuccin-mocha-pink-standard+rimless";
        package = pkgs.catppuccin-gtk.override {
          accents = [
            "blue"
            "pink"
          ];
          size = "standard";
          tweaks = [ "rimless" ];
          variant = "mocha";
        };
      };
      cursorTheme = {
        name = "catppuccin-mocha-pink-cursors";
        package = pkgs.catppuccin-cursors.mochaPink;
        size = 24;
      };
    };
    home.packages = with pkgs; [ glib ];
  };
}
