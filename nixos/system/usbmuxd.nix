{
  pkgs,
  ...
}:
{
  content.services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };
}
