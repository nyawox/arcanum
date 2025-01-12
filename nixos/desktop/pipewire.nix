{
  lib,
  pkgs,
  ...
}:
with lib;
{
  content = {
    # rtkit is optional but recommended
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber = {
        enable = true;
        configPackages = singleton (
          pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez.conf"
            # conf
            ''
              monitor.bluez.properties = {
                bluez5.enable-sbc-xq = true
                bluez5.enable-msbc = true
                bluez5.enable-hw-volume = true
                bluez5.codecs = [ sbc sbc_xq aac ]
              }
            ''
        );
      };
    };
  };
  userPersist = {
    directories = [ ".local/state/wireplumber" ];
    files = [ ".config/pulse/cookie" ];
  };
}
