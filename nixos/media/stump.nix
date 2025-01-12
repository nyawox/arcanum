# i gave up packaging, can't get prisma to work
{
  lib,
  arcanum,
  ...
}:
with lib;
{
  # systemctl --user daemon-reload
  homeConfig.services.podman.containers."stump" = {
    image = "docker.io/aaronleopold/stump:nightly";
    autoStart = true;
    autoUpdate = "registry";
    volumes = [
      "/var/lib/stump/config:/config"
      "/var/lib/stump/data:/data"
    ];
    environment = {
      STUMP_VERBOSITY = 3;
      ENABLE_KOREADER_SYNC = true;
      ENABLE_UPLOAD = true;
      MAX_FILE_UPLOAD_SIZE = 314572800; # comics cbz files are usually few hundred mbs
      MAX_IMAGE_UPLOAD_SIZE = 314572800;
    };
    network = singleton "shared";
    networkAlias = singleton "stump";
    ports = singleton "10801:10801";
  };
  content = {
    modules.virtualisation.podman.enable = mkForce true;
    modules.backup.restic = {
      enable = true;
      list = singleton {
        name = "podman-stump";
        path = "/var/lib/stump/config";
        user = arcanum.username;
        group = "users";
      };
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/stump";
    user = arcanum.username;
    group = "users";
    mode = "640";
  };
}
