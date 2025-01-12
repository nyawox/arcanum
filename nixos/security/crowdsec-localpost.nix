# go compiler from nixpkgs builds for wrong architecture
{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  vaultwarden-acquis = pkgs.writeTextFile {
    name = "vaultwarden-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
          - "SYSLOG_IDENTIFER=vaultwarden"
        labels:
          type: Vaultwarden
      '';
  };
  adguard-acquis = pkgs.writeTextFile {
    name = "adguard-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
         - "SYSLOG_IDENTIFIER=adguardhome"
        labels:
          type: adguardhome
      '';
  };
  grafana-acquis = pkgs.writeTextFile {
    name = "grafana-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
         - "SYSLOG_IDENTIFIER=grafana"
        labels:
          type: grafana
      '';
  };
  forgejo-acquis = pkgs.writeTextFile {
    name = "forgejo-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
         - "SYSLOG_IDENTIFIER=forgejo"
        labels:
          type: gitea
      '';
  };
  paperless-acquis = pkgs.writeTextFile {
    name = "paperless-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
         - "SYSLOG_IDENTIFIER=paperless"
        labels:
          type: paperless-ngx
      '';
  };
  hass-acquis = pkgs.writeTextFile {
    name = "hass-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
         - "SYSLOG_IDENTIFIER=home-assistant"
        labels:
          type: home-assistant
      '';
  };
  sshd-acquis = pkgs.writeTextFile {
    name = "sshd-acquis.yaml";
    text = # yaml
      ''
        source: journalctl
        journalctl_filter:
         - "_SYSTEMD_UNIT=sshd.service"
        labels:
          type: syslog
      '';
  };
in
{
  homeConfig.services.podman.containers."crowdsec-localpost" = {
    image = "docker.io/crowdsecurity/crowdsec:latest-debian";
    autoStart = true;
    autoUpdate = "registry";
    volumes = [
      "/var/lib/crowdsec/config/:/etc/crowdsec" # config
      "/var/lib/crowdsec/data/:/var/lib/crowdsec/data/" # db
      "${vaultwarden-acquis}:/etc/crowdsec/acquis.d/vaultwarden.yaml"
      "${adguard-acquis}:/etc/crowdsec/acquis.d/adguardhome.yaml"
      "${grafana-acquis}:/etc/crowdsec/acquis.d/grafana.yaml"
      "${forgejo-acquis}:/etc/crowdsec/acquis.d/forgejo.yaml"
      "${paperless-acquis}:/etc/crowdsec/acquis.d/paperless.yaml"
      "${hass-acquis}:/etc/crowdsec/acquis.d/hass.yaml"
      "${sshd-acquis}:/etc/crowdsec/acquis.d/sshd.yaml"
      "/var/log/journal:/run/log/journal:ro"
    ];
    environmentFile = [ config.sops.secrets.crowdsec-localpost-env.path ];
    network = singleton "shared";
    networkAlias = singleton "crowdsec";
    ports = [
      "2465:8080"
      "6764:6060"
    ];
  };
  content = {
    sops.secrets.crowdsec-localpost-env = {
      sopsFile = "${arcanum.secretPath}/crowdsec-localpost.yaml";
      owner = arcanum.username;
      format = "yaml";
    };
    systemd = {
      user.services.podman-crowdsec-localpost.after = [ "var-lib-crowdsec.mount" ];
      tmpfiles.rules = [
        "d /persist/var/lib/crowdsec/config 0750 ${arcanum.username} users -"
        "d /persist/var/lib/crowdsec/data 0750 ${arcanum.username} users -"
      ];
    };
    modules.virtualisation.podman.enable = mkForce true;
  };
  persist.directories = singleton {
    directory = "/var/lib/crowdsec";
    user = arcanum.username;
    group = "users";
    mode = "640";
  };
}
