{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.services.netdata;
in
{
  options = {
    modules.services.netdata = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      sender = mkOption {
        type = types.bool;
        default = true;
      };
      receiver = mkOption {
        type = types.bool;
        default = false;
      };
      apikey = mkOption {
        type = types.str;
        default = "";
      };
      webui = mkOption {
        type = types.bool;
        default = if cfg.receiver then true else false;
      };
    };
  };
  config = mkIf cfg.enable {
    sops.secrets.netdata-ntfy = mkIf cfg.receiver {
      sopsFile = ../../../secrets/netdata-ntfy.env;
      owner = "netdata";
      format = "dotenv";
    };
    services.netdata = {
      enable = true;
      configDir."health_alarm_notify.conf" = mkIf cfg.receiver "${config.sops.secrets.netdata-ntfy.path}";
      configDir."stream.conf" =
        let
          mkChildNode =
            apiKey: allowFrom:
            # conf
            ''
              [${apiKey}]
                enabled = yes
                default history = 604800
                default memory mode = dbengine
                health enabled by default = auto
                allow from = ${allowFrom}
            '';
        in
        pkgs.writeText "stream.conf" ''
          [stream]
          enabled = ${if cfg.receiver then "no" else "yes"}
          enable compression = yes


          ${optionalString cfg.sender ''
            destination = localpost.hsnet.${arcanum.domain}:19999
            api key = ${cfg.apikey}
          ''}
          ${optionalString cfg.receiver ''
            # Allowed sender nodes
            # generate apikey with `uuidgen`
            # the ips are taken from `tailscale status`
            # localpost
            ${mkChildNode "a73b169d-3a46-46d1-b8d5-48bd53933f9a" "100.64.0.5"}
            # localghost
            ${mkChildNode "c96533b8-4709-48ea-862e-cca0871b72a4" "100.64.0.1"}
            # lolcathost
            ${mkChildNode "2e117745-b8b7-4f7b-8b50-e4df187e36ea" "100.64.0.8"}
            # localtoast
            ${mkChildNode "f17bc57e-969e-488c-ae8a-2ea69e319b35" "100.64.0.3"}
          ''}
        '';
      config = mkMerge [
        (mkIf (!cfg.webui) {
          # child nodes
          global."memory mode" = "none";
          web = {
            mode = "none";
            "accept a streaming request every seconds" = 0;
          };
          health.enabled = "no";
        })
        (mkIf cfg.sender {
          # all nodes including parent
          global."update every" = 5;
          db."dbengine page type" = "gorilla";
        })
      ];
    };
    environment.persistence."/persist".directories = mkIf config.modules.sysconf.impermanence.enable [
      "/var/lib/netdata"
    ];
  };
}
