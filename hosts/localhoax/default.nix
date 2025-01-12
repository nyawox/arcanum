{
  lib,
  config,
  arcanum,
  ...
}:
{
  modules = {
    system = {
      disko.disk.device = "/dev/vda";
      qemu-guest.enable = true;
      headless.enable = true;
    };
    security = {
      remoteunlock.enable = true;
      crowdsec-localhoax.enable = true;
      endlessh.enable = true;
    };
    servers = {
      open-webui.enable = true;
      postgresql.enable = true;
      snappymail.enable = true;
    };
    networking = {
      avahi.enable = false;
      tailscale = {
        exitNode = true;
        tags = [ "tag:admin-servers" ];
      };
      wireguard = {
        enable = true;
        exporter = true;
      };
    };
  };

  psilocybin.enable = false;

  networking = {
    defaultGateway = {
      address = "152.53.52.1";
      interface = "enp7s0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp7s0";
    };
    interfaces.enp7s0 = {
      ipv4.addresses = lib.singleton {
        address = arcanum.localhoax-ip4;
        prefixLength = 22;
      };
      ipv6.addresses = lib.singleton {
        address = arcanum.localhoax-ip;
        prefixLength = 64;
      };
    };
    firewall.extraInputRules = # py
      ''
        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420, 2022 } accept
        # 22420 ssh
        # 2022 et

        # localhoax
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.1/32 tcp dport { 6397, 5432 } accept
        # 6397 open-webui redis
        # 5432 open-webui pgsql

        # lokalhost caddy
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport { 11454, 8416 } accept
        # 11454 open-webui
        # 8416 snappymail

        # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9100, 2019, 9164, 9584, 6764, 9187 } accept
        # 9100 allow prometheus to access node_exporter
        # 9164 allow prometheus to access endlessh
        # 9584 prometheus wireguard
        # 6764 prometheus crowdsec
        # 9187 prometheus postgresql
      '';
  };

  boot.kernelParams = [
    "ip=${arcanum.localhoax-ip4}::152.53.52.1:255.255.255.0::enp7s0:off"
    "ip6=[${arcanum.localhoax-ip}]::[fe80::1]:64::enp7s0:off"
  ];
  users.groups.builder = { };
  users.users.builder = {
    isNormalUser = true;
    group = "builder";
    hashedPassword = "";
    home = "/home/builder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILomoIkXbf77CIS7igcGRCFJZt3lujhactfO6UriMNaT"
    ];
  };
  system.activationScripts.hardenBuilder = ''
    chmod -R a-w /home/builder
  '';
  nix.settings.trusted-users = [ "builder" ];
  services.openssh.extraConfig = ''
    AllowUsers builder
  '';
}
