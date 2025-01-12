{
  lib,
  ...
}:
{
  content.services.tor = {
    enable = true;
    client.enable = true;
    torsocks.enable = true;
    settings = {
      ControlPort = lib.singleton {
        port = 9051;
      };
      CookieAuthentication = true;
      DataDirectoryGroupReadable = true;
      CookieAuthFileGroupReadable = true;
    };
  };
}
