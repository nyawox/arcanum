{
  config,
  pkgs,
  ...
}:
{
  modules = {
    system.disko = {
      disk.device = "/dev/nvme0n1";
      esp.size = "256M";
      tmpfsroot.size = "256M";
    };
    networking = {
      avahi.enable = false;
      tailscale = {
        enable = true;
        tags = [ "tag:admin-servers" ];
      };
      wireguard = {
        enable = true;
        exporter = true;
      };
    };
    security = {
      remoteunlock.enable = true;
      crowdsec-localhostage.enable = true;
      endlessh.enable = true;
    };
  };
  networking = {
    timeServers = [ "169.254.169.123" ];
    firewall.extraInputRules = # py
      ''
        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420 } accept
        # 22420 ssh

        # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9100, 9164, 9584 } accept
        # allow prometheus to access node_exporter 9100 and wireguard 9584
        # 9164 allow prometheus to access endlessh
      '';
  };

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" ];
      kernelModules = [
        "igb"
        "xen-blkfront"
        "ena"
      ];
    };
    kernelParams = [
      "console=ttyS0,115200n8"
      "random.trust_cpu=on"
    ];
    extraModulePackages = [
      config.boot.kernelPackages.ena
    ];
  };
  systemd.services."serial-getty@ttyS0".enable = true;
  services.udev.packages = [ pkgs.amazon-ec2-utils ];
  environment.systemPackages = [ pkgs.cryptsetup ];

  users.groups.builder = { };
  users.users.builder = {
    isNormalUser = true;
    group = "builder";
    hashedPassword = "";
    home = "/home/builder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILomoIkXbf77CIS7igcGRCFJZt3lujhactfO6UriMNaT nyawox.git@gmail.com"
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
