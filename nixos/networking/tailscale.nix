{
  cfg,
  config,
  lib,
  pkgs,
  inputs,
  arcanum,
  ...
}:
with lib;
{
  options = {
    notifier = mkEnableOption "Taildrop Notifier";
    exitNode = mkEnableOption "Advertise as exit node";
    tags = mkOption {
      type = types.listOf types.str;
      default = [ "tag:admin" ];
    };
    setFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };
  imports = [ inputs.taildrop-notifier.nixosModules.taildrop-notifier ];
  content = {
    services = {
      tailscale = {
        enable = true;
        permitCertUid = arcanum.username;
        extraSetFlags = [
          "--operator=${arcanum.username}"
          (mkIf cfg.exitNode "--advertise-exit-node")
        ] ++ cfg.setFlags;
        extraDaemonFlags = [ "--no-logs-no-support" ];
        useRoutingFeatures = if cfg.exitNode then "server" else "client";
        interfaceName = "tailscale0";
      };
      taildrop-notifier = mkIf cfg.notifier {
        enable = true;
        user = arcanum.username;
      };
      networkd-dispatcher = mkIf cfg.exitNode {
        enable = true;
        rules."50-tailscale" = {
          onState = [ "routable" ];
          script = ''
            #! ${pkgs.runtimeShell}
            NETDEV=$(${pkgs.iproute2}/bin/ip -o route get 9.9.9.9 | cut -f 5 -d " ")
            ${getExe pkgs.ethtool} -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
          '';
        };
      };
    };
    systemd.services = {
      taildrop-notifier.serviceConfig.PrivateTmp = true;
      tailscaled.serviceConfig = {
        StandardOutput = "null";
      };
    };
    systemd.network.wait-online.ignoredInterfaces = [ "tailscale0" ];
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
  homeConfig = {
    programs.nushell.shellAliases.tsauth = ''
      sudo tailscale up --qr --operator=${arcanum.username} --login-server=https://hs.${arcanum.domain} --advertise-tags "${concatStringsSep "," cfg.tags}" ${optionalString cfg.exitNode "--advertise-exit-node"}
    '';
  };
  persist.directories = singleton "/var/lib/tailscale";
}
