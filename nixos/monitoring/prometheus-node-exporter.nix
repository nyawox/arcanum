_: {
  content.services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = 9100;
    # https://github.com/prometheus/node_exporter?tab=readme-ov-file#enabled-by-defaul
    enabledCollectors = [
      "systemd"
      "processes"
    ];
    # silence the permission denied error
    extraFlags = [
      "--collector.filesystem.mount-points-exclude='^/(persist/)?(home|var/lib/private|sys|proc|dev|etc|root|run)($$|/)'"
    ];
  };
}
