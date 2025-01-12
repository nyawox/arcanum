{
  lib,
  pkgs,
  config,
  arcanum,
  ...
}:
with lib;
let
  init = pkgs.writeShellScriptBin "init.sh" ''
    set -euo pipefail

    cscli hub update

    if ! cscli collections list | grep -q "linux"; then
        cscli collections install crowdsecurity/linux
    fi

    if ! cscli collections list | grep -q "auditd"; then
        cscli collections install crowdsecurity/auditd
    fi

    if ! cscli collections list | grep -q "endlessh"; then
        cscli collections install crowdsecurity/endlessh
    fi

    if ! cscli postoverflows list | grep -q "auditd-nix-wrappers-whitelist-process"; then
       cscli postoverflows install crowdsecurity/auditd-nix-wrappers-whitelist-process
    fi

  '';
in
{
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
          journalctl_filter = [ "SYSLOG_IDENTIFIER=endlessh-go" ];
          labels.type = "endlessh";
        }
      ];
      settings.api = {
        server.enable = false;
        client.credentials_path = "${config.sops.secrets.crowdsec-localhostage-secrets.path}";
      };
    };
    systemd = {
      services.crowdsec = {
        serviceConfig.ExecStartPre = [ "${getExe init}" ];
        after = [ "var-lib-crowdsec.mount" ];
      };
      tmpfiles.rules = [
        "d /persist/var/lib/crowdsec/config 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/data 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/hub 0750 crowdsec crowdsec -"
      ];
    };
    sops.secrets.crowdsec-localhostage-secrets = {
      sopsFile = "${arcanum.secretPath}/crowdsec-localhostage.yaml";
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
