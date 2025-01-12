# my favorite module
# tor load balancer
{
  lib,
  ...
}:
with lib;
let
  tor-circuit-number = 255; # 255 is the maximum ipv4 range
  generateOutbound = tag: sendThrough: {
    protocol = "socks";
    inherit sendThrough;
    inherit tag;
    settings.servers = singleton {
      address = "127.0.0.1";
      port = 9050;
    };
  };

  outbounds = genList (
    i: generateOutbound "tor-${toString (i + 1)}" "127.0.0.${toString (i + 1)}"
  ) tor-circuit-number;

  v2rayConfig = {
    log = {
      loglevel = "warning";
    };

    inbounds = singleton {
      port = 9052;
      listen = "127.0.0.1";
      protocol = "http";
      sniffing = {
        enabled = true;
        destOverride = [
          "http"
          "tls"
        ];
      };
    };

    inherit outbounds;

    routing = {
      rules = singleton {
        type = "field";
        network = "tcp";
        balancerTag = "balancer";
      };

      balancers = singleton {
        tag = "balancer";
        selector = [ "tor-" ];
        strategy = {
          type = "random";
        };
      };
    };
  };
in
{
  content.services.v2ray = {
    enable = true;
    config = v2rayConfig;
  };
}
