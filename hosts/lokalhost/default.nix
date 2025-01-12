{
  lib,
  config,
  arcanum,
  ...
}:
{
  modules = {
    system = {
      disko = {
        disk.device = "/dev/vda";
        esp.mbr = true;
      };
      qemu-guest.enable = true;
      headless.enable = true;
    };
    security = {
      remoteunlock.enable = true;
      crowdsec-lokalhost.enable = true;
      endlessh.enable = true;
      kanidm-server.enable = true;
      kanidm-client.enable = true;
      oauth2-proxy.enable = true;
    };
    servers = {
      acme.enable = true;
      caddy.enable = true;
      headplane.enable = true;
      homepage.enable = true;
      searxng.enable = true;
      mailserver.enable = true;
    };
    networking = {
      avahi.enable = false;
      headscale.enable = true;
      tailscale = {
        exitNode = true;
        tags = [ "tag:admin-servers" ];
      };
      wireguard = {
        enable = true;
        exporter = true;
      };
      tor.enable = true;
      v2ray.enable = true;
    };
  };

  psilocybin.enable = false;

  networking = {
    defaultGateway = {
      address = arcanum.lokalhost-gateway4;
      interface = "ens3";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "ens3";
    };
    interfaces.ens3 = {
      ipv4.addresses = lib.singleton {
        address = arcanum.lokalhost-ip4;
        prefixLength = 22;
      };
      # enable ipv6
      ipv6.addresses = lib.singleton {
        address = arcanum.lokalhost-ip;
        prefixLength = 64;
      };
    };
    firewall.extraInputRules = # py
      ''
        # lokalhost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport { 8082, 8420, 8085, 9191, 6484, 7424, 4348, 16544, 8642 } accept
        # 8082 homepage dashboard
        # 8420 searxng
        # 8085 headscale
        # 9191 headplane
        # 4348 kanidm
        # 16544 oauth2-proxy
        # 6484 crowdsec caddy and nftables
        # 7424 caddy crowdsec appsec
        # 8642 radicale

        # localhoax open-webui direct access to searxng
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.1/32 tcp dport { 8420 } accept

        # crowdsec
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.8/32 tcp dport 6484 accept # localhostage
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.7/32 tcp dport 6484 accept # localcoast
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport 6484 accept # lokalhost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.5/32 tcp dport 6484 accept # localghost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.4/32 tcp dport 6484 accept # localtoast
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport 6484 accept # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport 6484 accept # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.1/32 tcp dport 6484 accept # localhoax

        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420, 2022 } accept
        # 22420 ssh
        # 2022 et

        # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9100, 2019, 9164, 9584, 6764 } accept
        # 9100 allow prometheus to access node_exporter
        # 2019 allow prometheus to access caddy
        # 9164 allow prometheus to access endlessh
        # 9584 prometheus wireguard
        # 6764 prometheus crowdsec
      '';
  };

  boot.kernelParams = [
    "ip=${arcanum.lokalhost-ip4}::${arcanum.lokalhost-gateway4}:255.255.255.0::ens3:off"
    "ip6=[${arcanum.lokalhost-ip}]::[fe80::1]:64::ens3:off"
  ];
}
