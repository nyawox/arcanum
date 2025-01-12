{
  lib,
  pkgs,
  inputs,
  config,
  arcanum,
  ...
}:
with lib;
let
  collections = [
    "crowdsecurity/linux"
    "crowdsecurity/auditd"
    "LePresidente/adguardhome"
  ];
  init = pkgs.writeShellScriptBin "init.sh" ''
    set -euo pipefail

    cscli hub update

    ${builtins.concatStringsSep "\n" (
      map (collection: ''
        if ! cscli collections list | grep -q "${builtins.baseNameOf collection}"; then
          cscli collections install ${collection}
        fi
      '') collections
    )}

    if ! cscli postoverflows list | grep -q "auditd-nix-wrappers-whitelist-process"; then
       cscli postoverflows install crowdsecurity/auditd-nix-wrappers-whitelist-process
    fi

  '';
in
{
  imports = [ inputs.crowdsec.nixosModules.crowdsec ];
  content = {
    services.crowdsec = {
      enable = true;
      allowLocalJournalAccess = true;
      acquisitions = [
        {
          filenames = [ "/var/log/audit/*.log" ];
          labels.type = "auditd";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "SYSLOG_IDENTIFIER=adguardhome" ];
          labels.type = "adguardhome";
        }
      ];
      settings = {
        api = {
          server.enable = false;
          client.credentials_path = "${config.sops.secrets.crowdsec-localtoast-secrets.path}";
        };
        prometheus = {
          enabled = true;
          level = "full";
          listen_addr = "0.0.0.0";
          listen_port = 6764;
        };
      };
    };
    systemd = {
      services.crowdsec = {
        after = [ "var-lib-crowdsec.mount" ];
        serviceConfig.ExecStartPre = [ "${getExe init}" ];
      };
      tmpfiles.rules = [
        "d /persist/var/lib/crowdsec/config 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/data 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/hub 0750 crowdsec crowdsec -"
      ];
    };
    sops.secrets.crowdsec-localtoast-secrets = {
      sopsFile = "${arcanum.secretPath}/crowdsec-localtoast.yaml";
      owner = "crowdsec";
      format = "yaml";
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/crowdsec";
    user = "crowdsec";
    group = "crowdsec";
    mode = "750";
  };
}
