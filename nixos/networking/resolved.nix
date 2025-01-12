{
  config,
  lib,
  ...
}:
{
  content.services.resolved = {
    enable = true;
    dnsovertls = "opportunistic";
    dnssec = lib.mkForce "allow-downgrade"; # don't want it to fail. i use adguardhome anyway
    # fix conflict with adguardhome
    extraConfig = ''
      ${lib.optionalString config.modules.networking.adguardhome.enable ''
        [Resolve]
        DNS=127.0.0.1
        DNSStubListener=no
      ''}
    '';
  };
}
