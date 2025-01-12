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
    sshAgent = lib.mkEnableOption "Enable goldwarden ssh agent";
  };
  homeConfig = {
    home.file.".mozilla/native-messaging-hosts/com.8bit.bitwarden.json".source =
      lib.mkIf cfg.biometrics "${pkgs.goldwarden}/lib/mozilla/native-messaging-hosts/com.8bit.bitwarden.json";
    programs.nushell.shellAliases.gwssh = "env SSH_AUTH_SOCK=/home/${arcanum.username}/.goldwarden-ssh-agent.sock ssh -o IdentitiesOnly=no";
  };
  content = {
    programs.goldwarden = {
      enable = true;
      useSshAgent = lib.mkIf cfg.sshAgent true;
    };
    systemd.user.services.goldwarden.environment = {
      GOLDWARDEN_API_URI = "https://vault.${arcanum.domain}";
    };
  };
  userPersist.directories = lib.singleton ".config/goldwarden";
}
