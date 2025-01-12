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
    "crowdsecurity/caddy"
    "crowdsecurity/endlessh"
    "crowdsecurity/appsec-virtual-patching"
    "crowdsecurity/appsec-generic-rules"
    "crowdsecurity/appsec-crs"
    "crowdsecurity/postfix"
    "crowdsecurity/dovecot"
  ];

  machines = [
    "lokalhost"
    "localpost"
    "localtoast"
    "lolcathost"
    "localhoax"
    "localghost"
    "localcoast"
    "localhostage"
  ];

  bouncers = [
    "caddy"
    "lokalhost-firewall"
    "localhoax-firewall"
    "localghost-firewall"
    "localcoast-firewall"
    "localhostage-firewall"
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

    if ! cscli parsers list | grep -q "whitelists"; then
      cscli parsers install crowdsecurity/whitelists # private ipv4 range
    fi

    ${builtins.concatStringsSep "\n" (
      map (hostname: ''
        if ! cscli machines list | grep -q "${hostname}"; then
          ${
            if hostname == "lokalhost" then
              "cscli machines add \"${hostname}\" --auto --force"
            else
              "cscli machines add \"${hostname}\" --password \"\$${lib.strings.toUpper hostname}_PASS\" -f -"
          }
        fi
      '') machines
    )}

    # Add bouncer
    ${builtins.concatStringsSep "\n" (
      map (bouncer: ''
        if ! cscli bouncer list | grep -q "${bouncer}"; then
          cscli bouncers add ${bouncer} --key ''$${
            lib.replaceStrings [ "-" ] [ "_" ] (lib.strings.toUpper bouncer)
          }_APIKEY
        fi
      '') bouncers
    )}
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
      enrollKeyFile = config.sops.secrets.crowdsec-lokalhost-key.path;
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
          filenames = [ "/var/log/caddy/*.log" ];
          labels.type = "caddy";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "SYSLOG_IDENTIFIER=endlessh-go" ];
          labels.type = "endlessh";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "SYSLOG_IDENTIFIER=postfix" ];
          labels.type = "postfix";
        }
        {
          source = "journalctl";
          journalctl_filter = [ "SYSLOG_IDENTIFIER=dovecot2" ];
          labels.type = "dovecot";
        }
        {
          appsec_configs = [
            "crowdsecurity/appsec-default"
            "crowdsecurity/crs"
          ];
          labels.type = "appsec";
          listen_addr = "0.0.0.0:7424";
          source = "appsec";
        }
      ];
      settings = {
        api.server = {
          enable = true;
          listen_uri = "0.0.0.0:6484";
          trusted_ips = [ "10.100.0.0/24" ];
          profiles_path =
            let
              default = (pkgs.formats.yaml { }).generate "default.yaml" {
                name = "default_ip_remediation";
                filters = singleton (
                  concatStringsSep " " [
                    "Alert.Remediation"
                    "=="
                    "true"
                    "&&"
                    "Alert.GetScope()"
                    "=="
                    "\"Ip\""
                    "&&"
                    "Alert.GetScenario()"
                    "not"
                    "in"
                    "[\"crowdsecurity/endlessh-bf\"]"
                  ]
                );
                decisions = singleton {
                  type = "ban";
                  duration = "6h";
                };
                duration_expr = "Sprintf('%dh', min((GetDecisionsCount(Alert.GetValue()) + 1) * 6, 48))"; # max of 48h
                notifications = singleton "http_default";
                on_success = "break";
              };
              ssh = (pkgs.formats.yaml { }).generate "ssh.yaml" {
                name = "endlessh_ip_remediation";
                filters = singleton (
                  concatStringsSep " " [
                    "Alert.Remediation"
                    "=="
                    "true"
                    "&&"
                    "Alert.GetScope()"
                    "=="
                    "\"Ip\""
                    "&&"
                    "Alert.GetScenario()"
                    "in"
                    "[\"crowdsecurity/endlessh-bf\"]"
                  ]
                );
                decisions = singleton {
                  type = "ban";
                  duration = "24h";
                };
                duration_expr = "Sprintf('%dh', min((GetDecisionsCount(Alert.GetValue()) + 1) * 24, 48))";
                on_success = "break";
              };
              resultYaml = pkgs.runCommand "profiles.yaml" { } ''
                cat ${default} >> $out
                echo "---" >> $out
                cat ${ssh} >> $out
              '';
            in
            resultYaml;
        };
        config_paths = {
          notification_dir = "/var/lib/crowdsec/notifications";
          plugin_dir = "/var/lib/crowdsec/plugins";
        };
        plugin_config = {
          user = "crowdsec";
          group = "crowdsec";
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
        api_key = ''''${LOKALHOST_FIREWALL_APIKEY}'';
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
          after = [ "var-lib-crowdsec.mount" ];
          serviceConfig = {
            EnvironmentFile = config.sops.secrets.crowdsec-lokalhost-env.path;
            ExecStartPre = [ "${getExe init}" ];
          };
        };
        crowdsec-firewall-bouncer = {
          after = [ "crowdsec.service" ];
          serviceConfig.EnvironmentFile = config.sops.secrets.crowdsec-lokalhost-env.path;
        };
      };
      tmpfiles.rules = [
        "d /persist/var/lib/crowdsec/config 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/data 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/hub 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/notifications 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/plugins 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/config/parsers 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/config/parsers/s02-enrich 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/config/postoverflows 0750 crowdsec crowdsec -"
        "d /persist/var/lib/crowdsec/config/postoverflows/s01-whitelist 0750 crowdsec crowdsec -"
        # from their docs: must be root-owned and non-world writable, and binaries/scripts must be named like
        # <plugin_type>-<plugin_subtype>
        # which is wrong, `crowdsec` user work in this case
        # due to the strict permission requirements, unfortunately direct symlink from nix store don't work
        # `sudo -u crowdsec cscli notifications test http_default`
        "C /persist/var/lib/crowdsec/plugins/notification-http 0740 crowdsec crowdsec - ${getExe' pkgs.crowdsec-notification-http "notification-http"}"
      ];
    };

    sops.secrets = {
      crowdsec-lokalhost-key = {
        sopsFile = "${arcanum.secretPath}/crowdsec-lokalhost.yaml";
        owner = "crowdsec";
        format = "yaml";
      };
      crowdsec-lokalhost-env = {
        sopsFile = "${arcanum.secretPath}/crowdsec-lokalhost.yaml";
        owner = "crowdsec";
        format = "yaml";
      };
      crowdsec-lokalhost-push = {
        sopsFile = "${arcanum.secretPath}/crowdsec-lokalhost.yaml";
        path = "/var/lib/crowdsec/notifications/http.yaml";
        owner = "crowdsec";
        format = "yaml";
      };
      crowdsec-lokalhost-vpnwl = {
        sopsFile = "${arcanum.secretPath}/crowdsec-lokalhost.yaml";
        path = "/var/lib/crowdsec/config/parsers/s02-enrich/vpn-whitelists.yaml";
        owner = "crowdsec";
        format = "yaml";
      };
      crowdsec-lokalhost-mywl = {
        sopsFile = "${arcanum.secretPath}/crowdsec-lokalhost.yaml";
        path = "/var/lib/crowdsec/config/postoverflows/s01-whitelist/mywl.yaml";
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
