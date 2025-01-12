{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
{
  modules = {
    system = {
      disko = {
        disk.device = "/dev/sda";
        tmpfsroot.size = "1G";
      };
      wifi.enable = true;
      laptop.enable = true;
      swapfile = {
        enable = true;
        size = 16384; # 16GiB
      };
      headless.enable = true;
    };
    servers.mealie.enable = true;
    networking = {
      tailscale.tags = [ "tag:admin-servers" ];
      wireguard = {
        enable = true;
        exporter = true;
      };
      adguardhome = {
        enable = true;
        openFirewall = true;
      };
      duckdns.enable = true;
    };
    monitoring = {
      loki.enable = true;
    };
    media = {
      stump.enable = true;
    };
    security = {
      secureboot.enable = true;
      tang.enable = true;
      remoteunlock.enable = true;
      # breaks remoteunlock and local adguardhome
      hardening.compatibility.disable-wifi-mac-rando = true;
      crowdsec-localtoast.enable = true;
    };
  };

  services = {
    switch-boot.enable = true;
    logind.lidSwitch = "ignore"; # disable suspend on close laptop lid
  };

  psilocybin = {
    jis.enable = true;
    devices = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
  };

  networking = {
    interfaces = {
      enp0s25.useDHCP = mkDefault true;
      wlan0.useDHCP = mkDefault true;
    };
    firewall.extraInputRules = # py
      ''
        # avahi
        iifname "enp0s25" udp dport 5353 accept

        # lokalhost allow promtail to access loki
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport { 3154 } accept

        # lokalhost caddy
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport { 3380, 10801, 8949 } accept
        # 3380 adguardhome
        # 10801 stump
        # 8949 mealie

        # localtoast
        # 3380 give adguard exporter access to metrics
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.4/32 tcp dport 3380 accept

        # localpost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 3154, 9100, 9618, 9584, 6764 } accept
        # 3154 allow grafana to access loki data source
        # 9100 allow prometheus to access node_exporter
        # 9618 allow prometheus to access adguard-home
        # 9584 wireguard prometheus exporter
        # 6764 crowdsec prometheus exporter

        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420, 2022 } accept
        # 22420 ssh
        # 2022 et
      '';
  };
  boot = {
    initrd = {
      systemd = {
        # disable annoying 1.5 minutes of boot delay
        tpm2.enable = false;
        units."dev-tpmrm0.device".enable = false;
      };
      kernelModules = [
        "i915"
        "e1000e" # ethernet module, necessary for remote unlock
      ];
    };

    extraModprobeConfig = ''
      options iwlwifi power_save=0 uapsd_disable=1 11n_disable=8
      options iwlmvm power_scheme=1
      # workaround frequent disconnections
      options mac80211 beacon_loss_count=100 max_nullfunc_tries=100 max_probe_tries=100 probe_wait_ms=5000 
    '';
  };

  environment.variables = {
    VDPAU_DRIVER = lib.mkIf config.hardware.graphics.enable (lib.mkDefault "va_gl");
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    graphics.extraPackages = with pkgs; [
      (
        if (lib.versionOlder (lib.versions.majorMinor lib.version) "23.11") then
          vaapiIntel
        else
          intel-vaapi-driver
      )
      libvdpau-va-gl
      intel-media-driver
    ];
    trackpoint.device = "TPPS/2 Elan TrackPoint";
  };
}
