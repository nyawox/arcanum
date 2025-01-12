{
  pkgs,
  inputs,
  ...
}:
let
  apple-fonts = inputs.apple-fonts.packages.${pkgs.system};
in
{
  imports = [ inputs.stylix.nixosModules.stylix ];
  content = {
    stylix = {
      enable = true;
      polarity = "dark";
      image = pkgs.fetchurl {
        url = "https://i.imgur.com/HcVYyjj.png";
        sha256 = "1xh1iw2h3wihjbnhl2hrqmzm53mq9id6m2nqy7ys5ggx578vhvl5";
      };
      imageScalingMode = "tile";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      fonts = {
        serif = {
          package = apple-fonts.sf-pro;
          # SF Pro Display is designed to be used at sizes above 20pt,
          # Use SF Pro Text for 19pt and below
          # Apple OS dynamically handles this
          name = "SF Pro Text";
        };

        sansSerif = {
          package = apple-fonts.sf-pro;
          name = "SF Pro Text";
        };

        monospace = {
          package = pkgs.spleen;
          name = "Spleen-6x12";
        };

        emoji = {
          package = pkgs.apple-emoji;
          name = "Apple Color Emoji";
        };
        sizes = {
          # font size in pt
          applications = 12;
          desktop = 12;
          popups = 12;
          terminal = 12;
        };
      };
      cursor = {
        package = pkgs.catppuccin-cursors.mochaPink;
        name = "catppuccin-mocha-pink-cursors";
        size = 24;
      };
      opacity = {
        applications = 0.93;
        terminal = 0.93;
      };
      targets = {
        console.enable = false;
        grub.enable = false;
        regreet.enable = false; # tries to inject null in non-nullable value
        plymouth = {
          logoAnimated = false;
          logo =
            let
              src-img = pkgs.fetchurl {
                url = "https://i.imgur.com/81ZNid0.png";
                sha256 = "13cx2f0ix4svafkr7rqh0r5fsk1490zs9dhhwfgxid7rfpswvhc0";
              };
            in
            pkgs.runCommand "resize-img" { } ''
              ${pkgs.imagemagick}/bin/magick ${src-img} -resize 30% $out
            '';
        };
      };
    };
  };
  homeConfig = {
    stylix = {
      enable = true;
      iconTheme = {
        enable = true;
        package = pkgs.whitesur-icon-theme.override {
          alternativeIcons = true;
          boldPanelIcons = true;
        };
        dark = "WhiteSur-dark";
        light = "WhiteSur-light";
      };
      targets = {
        waybar.enable = false;
        emacs.enable = false;
        alacritty.enable = false;
        foot.enable = false;
        helix.enable = false;
        zellij.enable = false;
        fuzzel.enable = false;
        bat.enable = false;
        nushell.enable = false;
        yazi.enable = false;
        vesktop.enable = false;
        niri.enable = false;
      };
    };
  };
}
