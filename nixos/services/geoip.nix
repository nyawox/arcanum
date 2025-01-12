{
  config,
  lib,
  arcanum,
  ...
}:
{
  content = {
    sops.secrets.geoip-key = {
      sopsFile = "${arcanum.secretPath}/geoip-secrets.yaml";
      format = "yaml";
    };
    services.geoipupdate = {
      enable = true;
      settings = {
        AccountID = 1104274;
        LicenseKey = {
          _secret = config.sops.secrets.geoip-key.path;
        };
        EditionIDs = [
          "GeoLite2-ASN"
          "GeoLite2-City"
          "GeoLite2-Country"
        ];
        DatabaseDirectory = "/var/lib/GeoIP";
      };
    };
  };
  persist.directories = lib.singleton "/var/lib/GeoIP";
}
