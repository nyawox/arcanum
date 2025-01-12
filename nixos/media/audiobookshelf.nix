{
  lib,
  ...
}:
with lib;
{
  content = {
    services.audiobookshelf = {
      enable = true;
      host = "0.0.0.0";
      port = 8465;
    };
    arcanum.sysUsers = [ "audiobookshelf" ];
  };
  persist.directories = singleton {
    directory = "/var/lib/audiobookshelf";
    user = "audiobookshelf";
    group = "audiobookshelf";
    mode = "750";
  };
}
