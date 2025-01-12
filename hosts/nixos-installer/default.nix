{
  pkgs,
  lib,
  arcanum,
  ...
}:
{
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHyGdHechQ+eGLGWB735OIw95sSjJfhZ7FPdpBaOeSvI"
  ];
  environment.systemPackages = [ pkgs.rsync ]; # for nixos-anywhere
  home-manager.users.${arcanum.username}.xdg = {
    # throws error without this
    mime.enable = lib.mkForce false;
    icons.enable = lib.mkForce false;
    autostart.enable = lib.mkForce false;
  };
}
