{ pkgs, lib, ... }:
with lib;
let
  plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "600614a9dc59a12a63721738498c5541c7923873";
    hash = "sha256-mQkivPt9tOXom78jgvSwveF/8SD8M2XCXxGY8oijl+o=";
  };
in
{
  content.modules.shell = {
    fzf.enable = true;
    zoxide.enable = true;
  };
  homeConfig = {
    programs.yazi = {
      enable = true;
      enableNushellIntegration = true;
      plugins = {
        full-border = "${plugins}/full-border.yazi";
        smart-filter = "${plugins}/smart-filter.yazi";
      };
      keymap.manager.prepend_keymap = [
        {
          on = singleton "F";
          run = "plugin smart-filter";
          desc = "Smart filter";
        }
        {
          on = singleton "f";
          run = "plugin fzf";
          desc = "Jump to a file/directory via fzf";
        }
        {
          on = singleton "z";
          run = "search --via=rg";
          desc = "Search files by content via ripgrep";
        }
        {
          on = singleton "j";
          run = "plugin zoxide";
          desc = "Jump to a directory via zoxide";
        }
      ];
      initLua = ''
        require("full-border"):setup()
      '';
    };
    xdg.configFile."yazi/theme.toml".source =
      "${pkgs.catppuccin-yazi}/themes/mocha/catppuccin-mocha-lavender.toml";
  };
}
