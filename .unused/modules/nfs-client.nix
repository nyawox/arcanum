# automount is disabled. run sudo mount [/nixboxes, /calibre, etc] to mount
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.services.nfs-client;
in
{
  options = {
    modules.services.nfs-client = {
      nixboxes = mkOption {
        type = types.bool;
        default = false;
      };
      calibre = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
  config = {
    fileSystems = {
      "/nixboxes" = mkIf cfg.nixboxes {
        device = "lolcathost:/nixboxes";
        fsType = "nfs";
        options = [
          "nfsvers=4.2"
          "x-systemd.automount"
          "noauto"
          "async"
        ];
      };
      "/calibre" = mkIf cfg.calibre {
        device = "localpost:/var/lib/calibre-server";
        fsType = "nfs";
        options = [
          "nfsvers=4.2"
          "nofail"
          "async"
        ];
      };
    };
  };
}
