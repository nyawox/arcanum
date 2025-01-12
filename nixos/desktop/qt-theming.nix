{
  lib,
  pkgs,
  ...
}:
with lib;
let
  variant = "mocha";
  accent = "pink";

  catppuccin-kvantum-pkg = pkgs.catppuccin-kvantum.override { inherit variant accent; };
  catppuccin = "catppuccin-${variant}-${accent}";
in
{
  homeConfig = {
    home.packages = [
      catppuccin-kvantum-pkg
      pkgs.libsForQt5.qtstyleplugin-kvantum
      pkgs.libsForQt5.qt5ct
    ];
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style.name = "kvantum";
    };

    xdg.configFile = {
      "Kvantum/${catppuccin}".source = "${catppuccin-kvantum-pkg}/share/Kvantum/${catppuccin}";
      "Kvantum/kvantum.kvconfig".source = (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
        General.theme = catppuccin;
      };
      qt5ct = {
        target = "qt5ct/qt5ct.conf";
        text = generators.toINI { } {
          Appearance = {
            icon_theme = "WhiteSur-dark";
          };
        };
      };

      qt6ct = {
        target = "qt6ct/qt6ct.conf";
        text = generators.toINI { } {
          Appearance = {
            icon_theme = "WhiteSur-dark";
          };
        };
      };
    };
  };
}
