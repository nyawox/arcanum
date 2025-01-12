{
  lib,
  arcanum,
  ...
}:
with lib;
{
  content = {
    networking = {
      networkmanager = {
        enable = true;
        wifi = {
          powersave = false;
          backend = "iwd";
        };
        connectionConfig."connection.mdns" = 2;
      };
      wireless.enable = false;
    };
    users.users."${arcanum.username}".extraGroups = lib.singleton "networkmanager";
    # Don't wait for network startup
    # https://old.reddit.com/r/NixOS/comments/vdz86j/how_to_remove_boot_dependency_on_network_for_a
    systemd.targets.network-online.wantedBy = mkForce [ ]; # Normally ["multi-user.target"]
    systemd.services.NetworkManager-wait-online.wantedBy = mkForce [ ]; # Normally ["network-online.target"]
  };
  persist.directories = singleton "/etc/NetworkManager/system-connections";
}
