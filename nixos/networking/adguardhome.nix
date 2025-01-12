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
  options = {
    openFirewall = mkOption {
      # Open port 53 for local use
      type = types.bool;
      default = false;
    };
    noLog = mkOption {
      type = types.bool;
      default = false;
    };
    slowMode = mkOption {
      # disable upstream with fast response time to make slow, useful for fallback dns. the behaviour depends on os implementation
      type = types.bool;
      default = false;
    };
  };
  content = {
    modules.networking.tailscale.tags = [ "tag:admin-adguard-home" ];
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 53 ];
    networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [ 53 ];

    arcanum.sysUsers = [
      "adguardhome"
      "prometheus-adguard-exporter"
    ];
    sops.secrets = {
      adguard-password = {
        sopsFile = "${arcanum.secretPath}/adguard-secrets.yaml";
        owner = "adguardhome";
        group = "adguardhome";
        format = "yaml";
        restartUnits = [ "adguardhome.service" ];
      };
      adguard-rules = {
        sopsFile = "${arcanum.secretPath}/adguard-secrets.yaml";
        owner = "adguardhome";
        group = "adguardhome";
        format = "yaml";
        restartUnits = [ "adguardhome.service" ];
      };
      adguard-exporter-env = {
        sopsFile = "${arcanum.secretPath}/adguard-secrets.yaml";
        owner = "prometheus-adguard-exporter";
        group = "prometheus-adguard-exporter";
        format = "yaml";
        restartUnits = [ "prometheus-adguard-exporter.service" ];
      };
    };

    services.adguardhome = {
      enable = true;
      allowDHCP = true;
      port = 3380;
      mutableSettings = false;
      settings = {
        users = [
          {
            name = "Drum3030";
            password = "TOBEREPLACED";
          }
        ];
        dns = {
          ratelimit = 0;
          upstream_code = "parallel";
          upstream_dns = [
            (mkIf (!cfg.slowMode) "https://dns.quad9.net/dns-query")
            "https://se-sto-dns-001.mullvad.net/dns-query"
            "https://se-mma-dns-001.mullvad.net/dns-query"
            "https://se-got-dns-001.mullvad.net/dns-query"
          ];
          bootstrap_dns = [
            "76.76.2.0"
            "76.76.10.0"
            "2606:1a40::"
            "2606:1a40:1::"
          ]; # controld
          use_http3_upstreams = true;
          serve_http3 = true;
          enable_dnssec = true;

          cache_optimistic = true;
          cache_size = 500000000; # 500 megabytes in bytes
          cache_ttl_max = 3600; # 1 hour in seconds
        };
        filtering = {
          protection_enabled = true;
          filtering_enabled = true;
          blocking_mode = "null_ip";
          filters_update_interval = 24;
        };
        statistics = {
          enabled = mkIf cfg.noLog false;
          interval = "720h"; # 30days
        };
        querylog = {
          enabled = mkIf cfg.noLog false;
          size_memory = 50;
          interval = "720h"; # 30days
        };
        tls.enabled = true;
        filters =
          imap
            (index: elem: {
              enabled = true;
              name = toString index;
              id = index;
              url = elem;
            })
            [
              "https://big.oisd.nl" # OISD Big List
              "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/ultimate.txt" # HaGeZi's Ultimate DNS Blocklist
              "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt" # HaGeZi's Threat Intelligence Feeds DNS Blocklist
              "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/hoster.txt" # HaGeZi's Badware Hoster DNS Blocklist
              "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/GameConsoleAdblockList.txt" # Game Console Adblock List
              "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/refs/heads/master/SmartTV-AGH.txt" # Smart-TV Blocklist for AdGuard Home (by Dandelion Sprout)
              "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-referral.txt" # HaGeZi's Allowlist Referral
              "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt" # URL Shortener
            ];
      };
    };
    systemd.services = {
      adguardhome = {
        environment = {
          GOMEMLIMIT = "100MiB";
          GOGC = "40";
        };
        serviceConfig = {
          Nice = mkForce (-20);
          IOWeight = mkForce 10000;
          CPUWeight = mkForce 10000;
        };
        preStart = mkAfter ''
          PASSWORD=$(cat ${config.sops.secrets."adguard-password".path})
          ${getExe pkgs.gnused} -i "s,TOBEREPLACED,$PASSWORD," "$STATE_DIRECTORY/AdGuardHome.yaml"
          user_rules=$(cat ${config.sops.secrets."adguard-rules".path})
          echo "$user_rules" >> "$STATE_DIRECTORY/AdGuardHome.yaml"
        '';
      };
      prometheus-adguard-exporter = mkIf (!cfg.noLog) {
        enable = true;
        description = "AdGuard exporter for Prometheus";
        wantedBy = [ "multi-user.target" ];
        environment = {
          ADGUARD_SERVERS = "http://${hostname}.${arcanum.internal}:3380";
          INTERVAL = "15s";
        };
        serviceConfig = {
          # port defaults to 9618
          ExecStart = ''
            ${pkgs.adguard-exporter}/bin/adguard-exporter
          '';
          EnvironmentFile = config.sops.secrets.adguard-exporter-env.path;
          Restart = "always";
          RestartSec = 5;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "full";
          DevicePolicy = "closed";
          NoNewPrivileges = true;
          DynamicUser = true;
          WorkingDirectory = "/tmp";
        };
      };
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/private/AdGuardHome";
    user = "adguardhome";
    group = "adguardhome";
    mode = "750";
  };
}
