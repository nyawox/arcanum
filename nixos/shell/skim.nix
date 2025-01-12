{
  pkgs,
  ...
}:
{
  homeConfig = {
    programs.skim.enable = true;
    programs.nushell.plugins = [ pkgs.nushellPlugins.skim ];
    home.packages = [ pkgs.nushellPlugins.skim ];
  };
}
