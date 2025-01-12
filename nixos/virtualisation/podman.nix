{
  lib,
  pkgs,
  ...
}:
with lib;
{
  homeConfig = {
    home.packages = with pkgs; [ podman-compose ];
    services.podman = {
      enable = true;
      autoUpdate.enable = true;
      networks.shared = {
        autoStart = true;
        description = "Default network to be shared";
        subnet = "192.168.20.0/24";
        gateway = "192.168.20.1";
        driver = "bridge";
        internal = false;
        extraPodmanArgs = [
          "--ipam-driver host-local"
        ];
      };
    };
  };
  content.modules.security.hardening = {
    desktop.allow-unprivileged-userns = true; # podman won't function without this
    compatibility.allow-ip-forward = true; # enable ip forwarding, required for external access
  };
  persist.directories = singleton "/var/lib/containers";
  userPersist.directories = singleton ".local/share/containers";
}
