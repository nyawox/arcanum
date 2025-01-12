{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.services.nfs-server;
in
{
  options = {
    modules.services.nfs-server = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
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
  config = mkIf cfg.enable {
    services.nfs.server.enable = true;
    services.nfs.server.exports = concatStringsSep "\n" [
      (optionalString cfg.nixboxes "/nixboxes *(rw,async,no_subtree_check)")
      (optionalString cfg.calibre "/var/lib/calibre-server *(rw,async,no_subtree_check,all_squash,anonuid=986,anongid=983)")
    ];
  };
}
