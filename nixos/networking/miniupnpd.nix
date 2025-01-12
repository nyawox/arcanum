{ cfg, lib, ... }:
with lib;
{
  options = {
    interface = mkOption {
      type = types.nullOr types.str;
      description = "External interface for miniupnpd";
    };
    allowedPorts = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            start = mkOption {
              type = types.int;
              description = "Start of port range";
            };
            end = mkOption {
              type = types.int;
              description = "End of port range";
            };
          };
        }
      );
      default = [ ];
      example = [
        {
          start = 1024;
          end = 65535;
        }
        {
          start = 80;
          end = 80;
        }
      ];
      description = "List of allowed port ranges";
    };
    internalIP = mkOption {
      type = types.str;
      default = "192.168.0.0/24";
      description = "Internal IP subnet";
    };
  };
  content = {
    services.miniupnpd = {
      enable = true;
      externalInterface = cfg.interface;
      internalIPs = [ cfg.interface ];
      natpmp = true;
      upnp = true;
      appendConfig = ''
        secure_mode = yes
        ext_perform_stun = yes
        ext_stun_host = stun.nextcloud.com
        ${concatMapStrings (
          range:
          "allow ${toString range.start}-${toString range.end} ${cfg.internalIP} ${toString range.start}-${toString range.end}\n"
        ) cfg.allowedPorts}

        # Deny all other ports
        deny 0-65535 0.0.0.0/0 0-65535
      '';
    };

    networking = {
      networkmanager.unmanaged = [ "miniupnpd" ];
      firewall.allowedUDPPorts = [
        1900 # sddp
        5351 # nat port mapping
        3478 # stun
      ];
    };

    networking.nftables.tables.upnp = {
      family = "inet";
      content = ''
        chain masq {
          type nat hook postrouting priority 100;
          ip saddr 192.168.0.0/24 oifname "${cfg.interface}" masquerade
        }
      '';
    };
    assertions = [
      {
        assertion = cfg.interface != null;
        message = "Interface is required to enable miniupnpd";
      }
      {
        assertion = cfg.allowedPorts != [ ];
        message = "All ports are denied by default. You need to explicitly allow port ranges.";
      }
    ];
  };
}
