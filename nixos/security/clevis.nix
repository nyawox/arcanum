{
  lib,
  pkgs,
  ...
}:
with lib;
{
  content = {
    environment.systemPackages = with pkgs; [ clevis ];
    boot.initrd.network.enable = true;
    boot.initrd.clevis = {
      enable = true;
      useTang = true;
    };
  };
}
