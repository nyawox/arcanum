{
  lib,
  pkgs,
  ...
}:
{
  homeConfig = {
    home.packages = [
      # required for direnv
      pkgs.gnugrep
    ];
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
  userPersist.directories = lib.singleton ".local/share/direnv";
}
