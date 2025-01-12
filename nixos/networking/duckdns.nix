{ config, arcanum, ... }:
{
  content = {
    services.duckdns = {
      enable = true;
      domainsFile = config.sops.secrets.duckdns-domains.path;
      tokenFile = config.sops.secrets.duckdns-token.path;
    };
    arcanum.sysUsers = [ "duckdns" ];
    sops.secrets = {
      duckdns-domains = {
        sopsFile = "${arcanum.secretPath}/duckdns-secrets.yaml";
        owner = "duckdns";
        group = "duckdns";
        format = "yaml";
        restartUnits = [ "duckdns.service" ];
      };
      duckdns-token = {
        sopsFile = "${arcanum.secretPath}/duckdns-secrets.yaml";
        owner = "duckdns";
        group = "duckdns";
        format = "yaml";
        restartUnits = [ "duckdns.service" ];
      };
    };
  };
}
