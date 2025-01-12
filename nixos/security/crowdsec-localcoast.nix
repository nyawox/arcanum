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
    "crowdsecurity/endlessh"
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
  imports = [
    inputs.crowdsec.nixosModules.crowdsec
    inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
  ];
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
      settings = {
        api = {
          server.enable = false;
          client.credentials_path = "${config.sops.secrets.crowdsec-localcoast-secrets.path}";
        };
        prometheus = {
          enabled = true;
          level = "full";
          listen_addr = "0.0.0.0";
          listen_port = 6764;
        };
      };
    };
    services.crowdsec-firewall-bouncer = {
      enable = true;
      package = inputs.crowdsec.packages.${pkgs.system}.crowdsec-firewall-bouncer;
      settings = {
        log_mode = "stdout";
        mode = "nftables";
        api_key = ''''${LOCALCOAST_FIREWALL_APIKEY}'';
        api_url = "http://lokalhost.${arcanum.internal}:6484";
        blacklists_ipv4 = "crowdsec-blacklists";
        blacklists_ipv6 = "crowdsec6-blacklists";
        nftables = {
          ipv4 = {
            table = "crowdsec";
            chain = "crowdsec-chain";
            enabled = true;
            set-only = true;
          };
          ipv6 = {
            table = "crowdsec6";
            chain = "crowdsec6-chain";
            enabled = true;
            set-only = true;
          };
        };
      };
    };
    # https://docs.crowdsec.net/u/bouncers/firewall/#set-only--nftables
    networking.nftables.tables = {
      crowdsec = {
        family = "ip";
        content = ''
          set crowdsec-blacklists {
            type ipv4_addr
            flags timeout
          }

          chain crowdsec-chain {
            type filter hook input priority filter; policy accept;
            ip saddr @crowdsec-blacklists tcp dport 22 accept comment "endlessh"
            ip saddr @crowdsec-blacklists drop
          }
        '';
      };
      crowdsec6 = {
        family = "ip6";
        content = ''
          set crowdsec6-blacklists {
            type ipv6_addr
            flags timeout
          }

          chain crowdsec6-chain {
            type filter hook input priority filter; policy accept;
            ip6 saddr @crowdsec6-blacklists tcp dport 22 accept comment "endlessh"
            ip6 saddr @crowdsec6-blacklists drop
          }
        '';
      };
    };
    systemd = {
      services = {
        crowdsec = {
          serviceConfig.ExecStartPre = [ "${getExe init}" ];
          after = [ "var-lib-crowdsec.mount" ];
        };
        crowdsec-firewall-bouncer = {
          after = [ "crowdsec.service" ];
          serviceConfig.EnvironmentFile = config.sops.secrets.crowdsec-localcoast-fwenv.path;
        };
      };
      tmpfiles.rules = [
        "d /persist/var/lib/crowdsec/config 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/data 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/hub 0750 crowdsec crowdsec -"
      ];
    };
    sops.secrets = {
      crowdsec-localcoast-secrets = {
        sopsFile = "${arcanum.secretPath}/crowdsec-localcoast.yaml";
        owner = "crowdsec";
        format = "yaml";
      };
      crowdsec-localcoast-fwenv = {
        sopsFile = "${arcanum.secretPath}/crowdsec-localcoast.yaml";
        owner = "crowdsec";
        format = "yaml";
      };
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/crowdsec";
    user = "crowdsec";
    group = "crowdsec";
    mode = "750";
  };
}
