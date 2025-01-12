{
  lib,
  ...
}:
{
  content = {
    networking.networkmanager.enable = lib.mkForce false;
    systemd.network.enable = true;
    networking.useNetworkd = true;
  };
}
