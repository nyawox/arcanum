{
  config,
  lib,
  arcanum,
  pkgs,
  inputs,
  hostname,
  ...
}:
with lib;
{
  extraConfig = [
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-vaultwarden = {
        sopsFile = "${arcanum.secretPath}/vaultwarden-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "vaultwarden" ];
        ensureUsers = singleton {
          name = "vaultwarden";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-vaultwarden.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "vaultwarden" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  content = {
    sops.secrets.vaultwarden-secrets = {
      sopsFile = "${arcanum.secretPath}/vaultwarden-secrets.yaml";
      owner = "vaultwarden";
      group = "vaultwarden";
      format = "yaml";
    };
    services.vaultwarden = {
      enable = true;
      package = inputs.small.legacyPackages.${pkgs.system}.vaultwarden;
      webVaultPackage = inputs.small.legacyPackages.${pkgs.system}.vaultwarden.webvault;
      dbBackend = "postgresql";
      # camel case (disable2FARemember) is automatically converted to upper snake case (DISABLE_2FA_REMEMBER)
      config = {
        rocketAddress = "0.0.0.0";
        rocketPort = 3011;
        # signupsAllowed = true;
        # signupsVerify = true;
        signupsAllowed = false;
        enableDbWal = "false";
        websocketEnabled = true;
        ipHeader = "X-Real-IP";
        domain = "https://vault.${arcanum.domain}"; # Enable WebAuthn authentication
        showPasswordHint = false;
        experimentalClientFeatureFlags = "autofill-overlay,autofill-v2,browser-fileless-import,extension-refresh,fido2-vault-credentials,ssh-key-vault-item,ssh-agent,inline-menu-positioning-improvements";
      };
      environmentFile = config.sops.secrets.vaultwarden-secrets.path;
    };
    modules.backup.restic = {
      enable = true;
      list = [
        {
          name = "vaultwarden";
          path = "/var/lib/bitwarden_rs";
        }
      ];
    };
  };
  persist.directories = singleton "/var/lib/bitwarden_rs";
}
