{
  lib,
  ...
}:
with lib;
{
  content = {
    services = {
      chrony = {
        enable = true;
        extraFlags = singleton "-F 1";
        enableRTCTrimming = false;
        servers = [
          "time.cloudflare.com"
          "ntspool1.time.nl"
          "nts.netnod.se"
          "ptbtime1.ptb.de"
          "time.dfm.dk"
          "time.cifelli.xyz"
        ];
        extraConfig = ''
          minsources 3
          authselectmode require
          dscp 46
          makestep 1.0 3
          rtconutc
          rtcsync
          cmdport 0
          noclientlog
        '';
      };
      timesyncd.enable = false;
      ntp.enable = false;
    };
  };
  persist.directories = singleton "/var/lib/chrony";
}
