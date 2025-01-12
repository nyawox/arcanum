{
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  gamePackages = with pkgs; [
    prismlauncher
    dolphin-emu
    rpcs3
    openrct2
  ];
in
{
  imports = [ inputs.jovian.nixosModules.default ];
  content = {
    modules.system.maxmem.enable = mkForce true;
    services.flatpak.packages = [
      "com.steamgriddb.SGDBoop"
      "io.github.limo_app.limo"
    ];
    jovian = {
      steam.enable = true;
      steam.updater.splash = "vendor";
      steamos.useSteamOSConfig = false;
      decky-loader.enable = true;
    };
    programs.steam = {
      enable = true;
      extraPackages = gamePackages ++ [ pkgs.lutris-unwrapped ];
    };
    environment.systemPackages = gamePackages ++ [ pkgs.lutris ];
  };
  persist.directories = singleton "/var/lib/decky-loader";
  userPersist.directories = [
    "Mods"
    "Games"
    "PopTracker"
    ".steam"

    ".local/share/Steam"
    ".local/share/lutris"
    ".local/share/umu"
    ".local/share/PrismLauncher"
    ".local/share/yuzu"
    ".local/share/dolphin-emu"

    ".config/dolphin-emu"
    ".config/rpcs3"
    ".config/OpenRCT2"
    ".config/heroic"
    ".config/lutris"
    ".config/Ryujinx"
  ];
}
