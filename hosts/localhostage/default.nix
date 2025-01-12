{
  config,
  ...
}:
{
  modules = {
    system = {
      disko = {
        disk = {
          device = "/dev/sda";
          encryption.pbkdf = "pbkdf2";
        };
        tmpfsroot.size = "512M";
      };
      swapfile = {
        enable = true;
        size = 1024; # 1GiB
      };
      qemu-guest.enable = true;
      headless.enable = true;
    };
    security = {
      remoteunlock.enable = true;
      crowdsec-localhostage.enable = true;
      endlessh.enable = true;
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
    firewall.extraInputRules = # py
      ''
        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420, 2022 } accept
        # 22420 ssh
        # 2022 et

        # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9100, 9584, 9164, 6764 } accept
        # 9100 allow prometheus to access node_exporter
        # 9584 prometheus wireguard
        # 9164 allow prometheus to access endlessh
        # 6764 prometheus crowdsec
      '';
  };

  boot.kernelParams = [ "console=ttyS0" ];
}
