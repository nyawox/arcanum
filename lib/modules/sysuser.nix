{ lib, config, ... }:
with lib;

let
  cfg = config.arcanum;
in
{
  options = {
    # helper to ensure systemd service users and groups exist
    # so impermanence mount/sops secrets installation don't fail
    arcanum.sysUsers = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
  config = {
    users.groups = lib.listToAttrs (map (name: nameValuePair name { }) cfg.sysUsers);
    users.users = lib.listToAttrs (
      map (
        name:
        nameValuePair name {
          group = name;
          isSystemUser = true;
        }
      ) cfg.sysUsers
    );
  };
}
