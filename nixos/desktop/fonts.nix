{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  apple-fonts = inputs.apple-fonts.packages.${pkgs.system};
  FREETYPE_PROPERTIES = concatStringsSep " " [
    "truetype:interpreter-version=40"
    "autofitter:no-stem-darkening=0"
    "cff:no-stem-darkining=0"
    "type1:no-stem-darkening=0"
    "t1cid:no-stem-darkening=0"
  ];
in
{
  content = {
    fonts = {
      fontDir = {
        enable = true;
        decompressFonts = true;
      };
      packages = with pkgs; [
        corefonts
        spleen
        apple-emoji
        font-awesome
        migmix
        fast-font
        nerd-fonts.symbols-only
        apple-fonts.sf-pro
        apple-fonts.sf-compact
        apple-fonts.sf-mono
      ];
      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          style = "full";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
        defaultFonts = {
          emoji = [
            "Apple Color Emoji"
          ];
        };
      };
    };
    environment.variables = {
      inherit FREETYPE_PROPERTIES;
    };
  };
  homeConfig = {
    home.packages = config.fonts.packages;
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        emoji = [
          "Apple Color Emoji"
        ];
      };
    };
    programs.nushell.environmentVariables = {
      inherit FREETYPE_PROPERTIES;
    };
  };
}
