{
  cfg,
  config,
  lib,
  pkgs,
  hostname,
  arcanum,
  ...
}:
with lib;
let
  wg-reset = pkgs.writeShellScriptBin "wg-reset" ''
    #!/usr/bin/env bash
    systemctl stop wgautomesh
    systemctl stop wireguard-${cfg.interface}
    rm /var/lib/private/wgautomesh/state
    systemctl start wireguard-${cfg.interface}
    systemctl start wgautomesh
  '';
in
{
  options = {
    interface = mkOption {
      type = types.str;
      default = "nova";
    };
    upnp = mkEnableOption "Try to redirect to this machine's wireguard daemon using UPnP IGD";
    exporter = mkEnableOption "export metrics to prometheus.";
    peers = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of the peer";
            };
            pubkey = mkOption {
              type = types.str;
              description = ''
                Public key of the peer.
                bash `wg pubkey < private`
                nu `open private | wg pubkey | save public`
              '';
            };
            address = mkOption {
              type = types.str;
              description = "Internal address";
            };
            endpoint = mkOption {
              type = types.nullOr types.str;
              description = "public endpoint";
              default = null;
            };
          };
        });
      default = [
        {
          name = "localhoax";
          pubkey = "L8HuOGKaAOggWFe731Ve5O5KF47UyrWNZ2IYNJUpjxk=";
          address = "10.100.0.1";
          endpoint = "${arcanum.localhoax-ip}:50281";
        }
        {
          name = "localpost";
          pubkey = "6r1LsneBAtS+2L2GfM2Ofs3oWTatLTAeuKRP5XUZTz8=";
          address = "10.100.0.2";
        }
        {
          name = "lolcathost";
          pubkey = "q6xt4l4G4aWcsgLW1KWsp+lzwdS2C46xEgC/PJCxAAQ=";
          address = "10.100.0.3";
        }
        {
          name = "localtoast";
          pubkey = "XGMpDVOBabx6K7haKed8/cc+a88HhQlyg/2bJMYmNWU=";
          address = "10.100.0.4";
        }
        {
          name = "localghost";
          pubkey = "3V5ArzoYfZuAZe27ulxBdPjXg3PXEdTwnkFHIqkylwk=";
          address = "10.100.0.5";
          endpoint = "${arcanum.localghost-ip}:50281";
        }
        {
          name = "lokalhost";
          pubkey = "wyS6s2hqvRZSGUSp/3gsUZkh5UgrOTTvrb1UqoV5HRg=";
          address = "10.100.0.6";
          endpoint = "${arcanum.lokalhost-ip}:50281";
        }
        {
          name = "localcoast";
          pubkey = "JXehQkp+njYkNjs3ficCN99596ihSIG97XtUskDphiw=";
          address = "10.100.0.7";
          endpoint = "${arcanum.localcoast-ip}:50281";
        }
        {
          name = "localhostage";
          pubkey = "F/jLTOUeVdyFk5PoOipJ7MocVBP5TFBh12xtioXFLHs=";
          address = "10.100.0.8";
          endpoint = "${arcanum.localhostage-ip4}:50281";
        }
      ];
    };
  };
  content =
    let
      currentPeer = lists.findFirst (
        peer: peer.name == hostname
      ) (throw "No peer configuration found for ${hostname}") cfg.peers;
    in
    {
      sops.secrets = {
        wgautomesh-gossip-secret = {
          sopsFile = "${arcanum.secretPath}/wgautomesh-secrets.yaml";
          owner = "wgautomesh";
          group = "wgautomesh";
          format = "yaml";
        };
        "wireguard-${hostname}-private" = {
          sopsFile = "${arcanum.secretPath}/wireguard-secrets.yaml";
          format = "yaml";
        };
      };
      systemd.network.wait-online.ignoredInterfaces = [ "${cfg.interface}" ];
      networking = {
        wireguard = {
          enable = true;
          interfaces.${cfg.interface} = {
            ips = [ "${currentPeer.address}/24" ];
            listenPort = 50281;
            privateKeyFile = config.sops.secrets."wireguard-${hostname}-private".path;
          };
        };
        firewall = {
          allowedUDPPorts = [
            50281
            (mkIf cfg.upnp 32768)
          ];
          # from README.md https://git.deuxfleurs.fr/Deuxfleurs/wgautomesh
          # > gossip communications occur inside the wireguard mesh network.
          interfaces.${cfg.interface}.allowedUDPPorts = [ 6666 ];
        };
        networkmanager.unmanaged = [ "${cfg.interface}" ];
        extraHosts = concatStringsSep "\n" (
          map (peer: "${peer.address} ${peer.name}.${cfg.interface}.${arcanum.domain}") cfg.peers
        );
      };
      services.wgautomesh = {
        enable = true;
        openFirewall = false;
        gossipSecretFile = config.sops.secrets.wgautomesh-gossip-secret.path;
        settings = {
          inherit (cfg) interface;
          gossip_port = 6666;
          upnp_forward_external_port = mkIf cfg.upnp 32768;
          lan_discovery = true;
          peers = map (peer: {
            inherit (peer) address pubkey endpoint;
          }) cfg.peers;
        };
      };
      arcanum.sysUsers = [ "wgautomesh" ];
      modules = {
        networking.miniupnpd.allowedPorts = mkIf cfg.upnp [
          {
            start = 32768;
            end = 32768;
          }
        ];
        # tailscale exit node also require this
        security.hardening.compatibility.allow-ip-forward = true;
      };
      services.prometheus.exporters.wireguard = mkIf cfg.exporter {
        enable = true;
        port = 9584;
        listenAddress = "0.0.0.0";
      };
    };
  homeConfig.home.packages = singleton wg-reset;
  persist.directories = singleton {
    directory = "/var/lib/private/wgautomesh";
    user = "wgautomesh";
    group = "wgautomesh";
    mode = "750";
  };
}
