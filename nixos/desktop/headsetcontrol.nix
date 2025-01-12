{
  pkgs,
  lib,
  ...
}:
{
  content = {
    environment.systemPackages = lib.singleton pkgs.headsetcontrol;
    services.udev.packages = lib.singleton pkgs.headsetcontrol;
  };
}
