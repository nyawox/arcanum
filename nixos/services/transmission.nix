{
  lib,
  pkgs,
  ...
}:
with lib;
# port 9091
{
  content.services.transmission = {
    enable = true; # Enable transmission daemon
    # home = "/mnt/transmission/";
    settings = {
      #Override default settings
      dht-enabled = true;
      encryption = 2;
      download-queue-enabled = false;
      # download-dir = "/mnt/transmission";
      rpc-bind-address = "0.0.0.0"; # Bind to own IP
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
    };
    webHome = pkgs.fetchzip {
      url = "https://github.com/6c65726f79/Transmissionic/releases/download/v1.8.0/Transmissionic-webui-v1.8.0.zip";
      sha256 = "9e68krz+xbKpng4WZyiol9oHBNZZ9T45HY4Zc4VTpAg=";
    };
  };
  persist.directories = singleton "/var/lib/transmission";
}
