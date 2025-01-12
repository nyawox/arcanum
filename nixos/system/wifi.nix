{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;

let
  ssids = [
    "wifi1"
    "wifi2"
    "wifi3"
    "wifi4"
    "wifi5"
    "wifi6"
    "wifi7"
    "wifi8"
    "wifi9"
    "wifi10"
    "wifi11"
    "wifi12"
    "wifi13"
    "wifi14"
    "wifi15"
  ];

  secretMappings = map (
    ssid:
    "C /var/lib/iwd/${config.sops.placeholder.${ssid}}.psk 0600 root root - ${
      config.sops.secrets.${ssid + "psk"}.path
    }"
  ) ssids;

  sopsSecrets =
    map (ssid: {
      name = ssid;
      value = {
        sopsFile = "${arcanum.secretPath}/wifissid.yaml";
        format = "yaml";
      };
    }) ssids
    ++ map (ssid: {
      name = ssid + "psk";
      value = {
        sopsFile = "${arcanum.secretPath}/${ssid}.psk";
        format = "binary";
      };
    }) ssids;

in
{
  content = {
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = true;
        };
        Network = {
          EnableIPv6 = true;
          RoutePriorityOffset = 300;
        };
        Settings = {
          AutoConnect = true;
        };
      };
    };
    systemd.network.wait-online.anyInterface = true;

    sops.secrets = builtins.listToAttrs sopsSecrets;

    sops.templates."wifi-tmpfiles.conf".content = builtins.concatStringsSep "\n" secretMappings;

    systemd.tmpfiles.packages = [
      (pkgs.runCommand "package-wifi-secrets" { } ''
        mkdir -p $out/lib/tmpfiles.d
        cd $out/lib/tmpfiles.d
        ln -s "${config.sops.templates."wifi-tmpfiles.conf".path}"
      '')
    ];
  };
  persist.directories = singleton "/var/lib/iwd";
}
