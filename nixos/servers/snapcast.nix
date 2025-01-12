{
  lib,
  ...
}:
{
  content = {
    modules.networking.tailscale.tags = [ "tag:admin-snap-server" ];
    services.pipewire.extraConfig.pipewire."70-snapserver-capture" = {
      context.modules = lib.singleton {
        name = "libpipewire-module-protocol-simple";
        args = {
          audio = {
            rate = 48000;
            format = "S16LE";
            channels = 2;
            position = [
              "FL"
              "FR"
            ];
          };
          server.address = [
            "tcp:4711"
          ];
          node.latency = "64/48000";
          capture = true;
          "capture.props" = {
            "node.name" = "snapcast";
            "node.description" = "Snapcast";
            "media.class" = "Audio/Sink";
          };
        };
      };
    };
    services.snapserver = {
      enable = true;
      buffer = 350;
      listenAddress = "0.0.0.0";
      port = 1704;
      tcp = {
        enable = true;
        port = 1705;
      };
      streams = {
        pipewire = {
          type = "tcp";
          location = "127.0.0.1:4711";
          query = {
            mode = "client";
            codec = "pcm";
            chunk_ms = "8";
          };
        };
      };
    };
  };
}
