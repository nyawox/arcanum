{
  cfg,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
{
  imports = [
    inputs.niri.nixosModules.niri
    inputs.niri-session-manager.nixosModules.niri-session-manager
  ];
  options.default = mkEnableOption "Make niri the default session";
  content = {
    modules.system.bluetooth.blueman = true;
    modules.desktop = {
      niri-config.enable = true;
      niri-login.enable = true;
      niri-lock.enable = true;
      niri-waybar.enable = true;
      niri-waybar-style.enable = true;
      niri-xwayland.enable = true;
      stylix.enable = true;
      qt-theming.enable = true;
      gtk-theming.enable = true;
      fonts.enable = true;
      foot.enable = true;
      fuzzel.enable = true;
      swaync.enable = true;
      inputmethod.enable = true;
    };
    services = {
      displayManager.defaultSession = mkIf cfg.default "niri";
      niri-session-manager.enable = true;
      gnome.gnome-keyring.enable = true;
    };
    programs = {
      niri = {
        enable = true;
        package = pkgs.niri-unstable;
      };
      # use seahorse for SSH_ASKPASS
      seahorse.enable = true;
      ssh.enableAskPassword = true;
    };
    security.polkit.enable = true;
    systemd.user.services = {
      niri-flake-polkit.enable = false;
      polkit-gnome-authentication-agent-1 = {
        enable = true;
        description = "Gnome polkit authentication agent";
        wantedBy = [
          "graphical-session.target"
          "niri.service"
        ];
        partOf = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
    environment = {
      variables.NIXOS_OZONE_WL = "1";
      systemPackages = with pkgs; [
        wl-clipboard
        wayland-utils
        libsecret
      ];
    };
  };
  userPerist.directories = singleton ".local/share/niri-session-manager";
}
