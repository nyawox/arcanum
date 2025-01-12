# requires home secrets
{
  lib,
  arcanum,
  ...
}:
with lib;
let
  syncAddress = "localpost.${arcanum.internal}:8878";
in
{
  homeConfig = {
    systemd.user.services.atuin-daemon.Unit.After = singleton "sops-nix.service";
    programs.atuin = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        sync_address = syncAddress;
        search_mode = "fuzzy";
        workspaces = true;
        history_filter = [
          "^curl"
          "^wget"
          "BEGIN OPENSSH PRIVATE KEY"
          "ssh-ed25519"
          "ssh-rsa"
          "ecdsa-sha2-nistp256"
        ];
      };
    };
  };
  userPersist.directories = singleton ".local/share/atuin";
}
