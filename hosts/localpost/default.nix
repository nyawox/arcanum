{ lib, config, ... }:
with lib;
{
  # Building man-cache on qemu is very slow.
  documentation.man.generateCaches = false;

  modules = {
    system = {
      disko.disk.device = "/dev/sda";
      bluetooth.enable = true;
      wifi.enable = true;
      swapfile.enable = true;
      headless.enable = true;
    };
    desktop.plymouth.enable = true;
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
    };
    security = {
      vaultwarden.enable = true;
      crowdsec-localpost.enable = true;
      remoteunlock.enable = true;
    };
    monitoring = {
      grafana.enable = true;
      prometheus.enable = true;
      healthchecks.enable = true;
      alertmanager.enable = true;
    };
    servers = {
      postgresql.enable = true;
      redis.enable = true;
      forgejo.enable = true;
      minio.enable = true;
      atuin.enable = true;
      paperless.enable = true;
      home-assistant.enable = true;
    };
    services = {
      firetv-launcher.enable = true;
    };
  };
  networking = {
    interfaces = {
      wlu1.useDHCP = mkDefault true;
      end0.useDHCP = mkDefault true;
      wlan0.useDHCP = mkDefault true;
    };
    firewall.extraInputRules = # py
      ''
        # avahi
        iifname "end0" udp dport 5353 accept
        iifname "wlan0" udp dport 5353 accept
        iifname "wlu1" udp dport 5353 accept

        # lokalhost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport { 3011, 3145, 3175, 3380, 8123, 8451, 9090, 9314, 9315, 28198, 9844 } accept
        # 3011 vaultwarden
        # 3145 git
        # 3175 grafana
        # 3380 adguardhome
        # 8123 hass
        # 8451 healthchecks
        # 9090 prometheus
        # 9314 minio s3 endpoint
        # 9315 minio webui
        # 28198 paperless
        # 9844 alertmanager

        # localpost prometheus exporters
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9187, 9618, 9100, 9584, 6764, 9314 } accept
        # 9187 postgresql
        # 9618 adguard-home
        # 9100 node-exporter
        # 9584 wireguard
        # 6764 crowdsec
        # 9314 minio

        # localpost prometheus alertmanager
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport 9844 accept

        # localpost
        # 3380 give adguard exporter access to metrics
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport 3380 accept

        # localpost paperless
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 6379 } accept
        # 6379 redis

        # localpost vaultwarden healthchecks grafana paperless forgejo
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 5432 } accept
        # 5432 postgres

        # localtoast mealie
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.4/32 tcp dport { 5432 } accept
        # 5432 postgres

        # lokalhost
        # crowdsec postgresql
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport 5432 accept
        # 5432 postgres

        # forgejo
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 6315, 9314 } accept
        # 6315 redis-forgejo
        # 9314 minio

        # allow localpost grafana to access prometheus
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.2/32 tcp dport { 9090 } accept

        # lolcathost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.3/32 tcp dport { 22420, 2022, 8878, 3024 } accept
        # 22420 ssh
        # 2022 et
        # 8878 atuin

        # localtoast
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.4/32 tcp dport { 6378, 9314 } accept
        # 6378 allow loki to access redis
        # 9314 allow loki to access minio

        # lokalhost
        iifname "${config.modules.networking.wireguard.interface}" ip saddr 10.100.0.6/32 tcp dport { 6420 } accept
        # 6420 allow searxng to access redis
      '';
  };

  boot = {
    # Use the systemd-boot EFI boot loader.
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = false;

    initrd.availableKernelModules = [
      "usbhid"
      # "sr_mod" # sd card and internal emmc storage
    ];
    initrd.kernelModules = [
      # Rockchip modules
      "rockchip_rga"
      "rockchip_saradc"
      "rockchip_thermal"
      "rockchipdrm"

      # GPU/Display modules
      "analogix_dp"
      "cec"
      "drm"
      "drm_kms_helper"
      "dw_hdmi"
      "dw_mipi_dsi"
      "gpu_sched"
      "panel_edp"
      "panel_simple"
      "panfrost"
      "pwm_bl"

      # USB / Type-C related modules
      "fusb302"
      "tcpm"
      "typec"
      "xhci_pci"

      # PCIE/NVMe/SATA
      "pcie_rockchip_host"
      "phy_rockchip_pcie"
      # "nvme"
      "ahci" # sata devices on modern ahci controllers
      "sd_mod" # scsi, sata and pata devices

      # ethernet, required for luks ssh
      "stmmac"
      "dwmac_rk"

      # Misc. modules
      "cw2015_battery"
      "gpio_charger"
      "rtc_rk808"
    ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [
      "igb.EEE=0"
      "plymouth.ignore-serial-consoles" # fix plymouth
    ];
  };
  psilocybin.enable = false;
  services.switch-boot.enable = true;

  nixpkgs.hostPlatform = mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = mkDefault "ondemand";
}
