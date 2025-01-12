{
  cfg,
  config,
  lib,
  pkgs,
  arcanum,
  hostname,
  ...
}:
with lib;
{
  options.bootstrapping = mkEnableOption "Enable when deploying the secrets";
  content = {
    # https://github.com/Mic92/sops-nix?tab=readme-ov-file#initrd-secrets
    # the secrets must be deployed before activating the rest
    sops.secrets.initrd-notificationenv = {
      sopsFile = "${arcanum.secretPath}/initrd-secrets.yaml";
      format = "yaml";
    };
    boot = {
      kernelParams = [ "ip=dhcp" ];
      initrd = {
        secrets = mkIf (!cfg.bootstrapping) {
          "/notification-env" = config.sops.secrets.initrd-notificationenv.path;
        };
        systemd = {
          storePaths = [
            "${getExe pkgs.curl}"
          ];
          services.boot-notification = {
            description = "Send notification";
            wantedBy = [ "initrd.target" ];
            path = [ pkgs.curl ];
            after = [
              "initrd-nixos-copy-secrets.service"
              "network.target"
            ];
            script = ''
              source /notification-env
              curl -s -F "token=$PUSH_TOKEN" \
                -F "user=$PUSH_USER" \
                -F "title=${hostname} reached initrd" \
                -F "message=Connect and enter the encryption key to continue the boot process" \
                -F "sound=gamelan" \
                $PUSH_URL
            '';
          };
        };
        network = {
          enable = true; # dw this still use networkd under the hood
          ssh = {
            enable = true;
            port = 42420;
            authorizedKeys = config.users.users."${arcanum.username}".openssh.authorizedKeys.keys;
            hostKeys = [ "/persist/etc/secrets/initrd/ssh_host_ed25519_key" ];
          };
        };
      };
    };
    services.openssh.hostKeys = singleton {
      path = "/persist/etc/secrets/initrd/ssh_host_ed25519_key";
      type = "ed25519";
    };
  };
  persist.directories = singleton "/etc/secrets/initrd";
}
