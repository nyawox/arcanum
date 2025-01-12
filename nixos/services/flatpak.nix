{
  cfg,
  lib,
  inputs,
  arcanum,
  ...
}:
with lib;
{
  imports = singleton inputs.nix-flatpak.nixosModules.nix-flatpak;
  homeImports = singleton inputs.nix-flatpak.homeManagerModules.nix-flatpak;
  options.fonts = mkOption {
    type = types.bool;
    default = false;
  };
  content = {
    services.flatpak = {
      enable = true;
      overrides = {
        global = {
          # Force Wayland by default
          Context.sockets = [
            "wayland"
            "!x11"
            "!fallback-x11"
          ];
        };
      };
    };
    # symlink fonts to user directory
    systemd.tmpfiles.rules = mkIf cfg.fonts [
      "L+ /home/${arcanum.username}/.local/share/fonts - - - - /run/current-system/sw/share/X11/fonts"
    ];
  };
  persist.directories = singleton "/var/lib/flatpak";
}
