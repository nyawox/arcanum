{
  pkgs,
  ...
}:
{
  homeConfig = {
    programs.gitui = {
      enable = true;
      theme = builtins.readFile "${pkgs.catppuccin-gitui}/themes/catppuccin-mocha.ron";
    };
  };
}
