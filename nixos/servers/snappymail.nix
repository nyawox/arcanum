{
  lib,
  arcanum,
  ...
}:
with lib;
{
  homeConfig.services.podman.containers."snappymail" = {
    image = "docker.io/djmaze/snappymail:latest";
    autoStart = true;
    autoUpdate = "registry";
    volumes = [ "/var/lib/snappymail:/var/lib/snappymail" ];
    network = singleton "shared";
    networkAlias = singleton "snappymail";
    ports = singleton "8416:8888";
  };
  content.modules.virtualisation.podman.enable = mkForce true;
  persist.directories = singleton {
    directory = "/var/lib/snappymail";
    user = arcanum.username;
    group = "users";
    mode = "700";
  };
}
