{
  cfg,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
{
  options = {
    allow-at-boot = mkEnableOption "Automatically whitelist all USB devices at boot in USBGuard.";
    gnome-integration = mkEnableOption "Enable USBGuard dbus daemon and polkit rules for integration with GNOME Shell.";
    notifier = mkEnableOption "Enable USBGuard notifier, notification daemon must be running";
  };
  content = {
    services.usbguard = {
      enable = true;
      presentDevicePolicy = mkIf cfg.allow-at-boot "allow";
      dbus.enable = mkIf cfg.gnome-integration true;
      IPCAllowedUsers = [
        "root"
        "${arcanum.username}"
      ];
    };
    environment.systemPackages = mkIf cfg.notifier [ pkgs.usbguard-notifier ];
    systemd.packages = mkIf cfg.notifier [ pkgs.usbguard-notifier ];
    systemd.user.services.usbguard-notifier = mkIf cfg.notifier {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
    };
    security.polkit.extraConfig = mkIf cfg.gnome-integration ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.usbguard.Policy1.listRules" ||
             action.id == "org.usbguard.Policy1.appendRule" ||
             action.id == "org.usbguard.Policy1.removeRule" ||
             action.id == "org.usbguard.Devices1.applyDevicePolicy" ||
             action.id == "org.usbguard.Devices1.listDevices" ||
             action.id == "org.usbguard1.getParameter" ||
             action.id == "org.usbguard1.setParameter") &&
             subject.active == true && subject.local == true &&
             subject.isInGroup("wheel")) { return polkit.Result.YES; }
      });
    '';
  };
  persist.directories = singleton "/var/lib/usbguard";
}
