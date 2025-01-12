{
  lib,
  pkgs,
  ...
}:
with lib;
{
  content = {
    modules.networking.avahi.enable = true;
    modules.system.usbmuxd.enable = true;
    services.gvfs = {
      enable = true;
      package = pkgs.gnome.gvfs;
    };
    networking.firewall = {
      # do not enable in servers
      allowedTCPPorts = singleton 5353;
      allowedUDPPorts = singleton 5353;
    };

    environment.systemPackages = with pkgs; [
      libimobiledevice
      ifuse
      gvfs
    ];
  };
  userPersist.directories = lib.singleton ".local/share/gvfs-metadata";
}
