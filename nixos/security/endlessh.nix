_: {
  content = {
    services.endlessh-go = {
      enable = true;
      listenAddress = "[::]";
      openFirewall = true;
      port = 22;
      extraOptions = [
        "-geoip_supplier=max-mind-db"
        "-max_mind_db=/var/lib/GeoIP/GeoLite2-City.mmdb"
        "-max_clients=8192"
        "-logtostderr"
        "-v=1"
      ];
      prometheus = {
        enable = true;
        listenAddress = "[::]";
        port = 9164;
      };
    };
    modules.services.geoip.enable = true;
    systemd.services.endlessh-go = {
      startLimitIntervalSec = 0;
      wants = [ "geoipupdate.service" ];
      after = [ "geoipupdate.service" ];
      serviceConfig.BindReadOnlyPaths = [ "/var/lib/GeoIP" ];
    };
  };
}
