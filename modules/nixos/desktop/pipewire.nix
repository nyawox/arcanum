{
  lib,
  config,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.pipewire;
in
{
  options = {
    modules.desktop.pipewire = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };
  config = mkIf cfg.enable {
    # rtkit is optional but recommended
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;
      extraConfig.pipewire = {
        "92-low-latency.conf" = {
          context.properties = {
            default.clock.rate = 48000;
            default.clock.quantum = 32;
            default.clock.min-quantum = 32;
            default.clock.max-quantum = 32;
          };
          context.modules = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                pulse.min.req = "32/48000";
                pulse.default.req = "32/48000";
                pulse.max.req = "32/48000";
                pulse.min.quantum = "32/48000";
                pulse.max.quantum = "32/48000";
              };
            }
          ];
          stream.properties = {
            node.latency = "32/48000";
            resample.quality = 1;
          };
        };
      };
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf" ''
            monitor.bluez.properties = {
              bluez5.enable-sbc-xq = true
              bluez5.enable-msbc = true
              bluez5.enable-hw-volume = true
              bluez5.codecs = [ sbc sbc_xq aac ]
            }
          '')
        ];
      };
    };
    environment.persistence."/persist".users."${username}" = {
      directories = [ ".local/state/wireplumber" ];
      files = [ ".config/pulse/cookie" ];
    };
  };
}
