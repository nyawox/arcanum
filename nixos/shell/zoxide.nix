{ lib, ... }:
{
  homeConfig.programs.zoxide = {
    enable = true;
    options = [
      "--cmd j"
    ];
  };
  userPersist.directories = lib.singleton ".local/share/zoxide";
}
