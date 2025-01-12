{
  pkgs,
  ...
}:
{
  homeConfig = {
    programs.bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "Catppuccin Mocha";
      };
    };
    xdg.configFile = {
      "bat/themes/Catppuccin Mocha.tmTheme".source =
        "${pkgs.catppuccin-bat}/themes/Catppuccin Mocha.tmTheme";
    };
    programs.nushell.environmentVariables.MANPAGER = "bat -l man -p";
  };
}
