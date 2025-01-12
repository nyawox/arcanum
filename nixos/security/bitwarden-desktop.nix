{
  cfg,
  lib,
  arcanum,
  pkgs,
  ...
}:
{
  options = {
    biometrics = lib.mkEnableOption "Enable firefox browser extension biometrics";
    sshAgent = lib.mkEnableOption "Enable bitwarden ssh agent";
  };
  content = {
    environment = {
      systemPackages = lib.singleton pkgs.bitwardenapp;
      extraInit =
        lib.mkIf cfg.sshAgent # bash
          ''
            if [ -z "$SSH_AUTH_SOCK" -a -n "$HOME" ]; then
              export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
            fi
          '';
    };
    # workaround a bug which agent won't start if the socket isn't alraedy in place until january release
    systemd.tmpfiles.rules = lib.singleton "f /home/${arcanum.username}/.bitwarden-ssh-agent.sock 0600 ${arcanum.username} wheel -";
  };
  homeConfig = {
    programs.nushell.shellAliases.bwssh = "env SSH_AUTH_SOCK=/home/${arcanum.username}/.bitwarden-ssh-agent.sock ssh -o IdentitiesOnly=no";
    home.file.".mozilla/native-messaging-hosts/com.8bit.bitwarden.json".text =
      lib.mkIf cfg.biometrics # json
        ''
          {
            "name": "com.8bit.bitwarden",
            "description": "Bitwarden desktop <-> browser bridge",
            "path": "${pkgs.bitwardenapp}/bin/desktop_proxy",
            "type": "stdio",
            "allowed_extensions": ["{446900e4-71c2-419f-a6a7-df9c091e268b}"]
          }
        '';
  };
  userPersist.directories = lib.singleton ".config/Bitwarden";
}
