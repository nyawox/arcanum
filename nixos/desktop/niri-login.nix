{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  theme = arcanum.homeCfg.gtk.theme.package;
  theme-name = arcanum.homeCfg.gtk.theme.name;
  theme-css = "${theme}/share/themes/${theme-name}/gtk-3.0/gtk.css";
in
{
  content = {
    programs.regreet = {
      enable = true;
      font = {
        inherit (config.stylix.fonts.sansSerif) name package;
      };
      cursorTheme = {
        inherit (config.stylix.cursor) name package;
      };
      theme = {
        package = pkgs.adw-gtk3;
        name = "adw-gtk3";
      };
      settings.appearance.greeting_msg = builtins.readFile config.environment.etc.issue.source;
    };
    environment.etc."greetd/regreet.css".source = mkForce theme-css;
    services.greetd = {
      enable = true;
      vt = 2;
      settings =
        let
          niri-session = "/run/current-system/sw/bin/niri-session"; # use the latest installed version, instead of store path, which quickly becomes outdated
          niri-logincfg = pkgs.writeText "niri-logincfg.kdl" ''
            spawn-at-startup "${getExe pkgs.swaybg}" "-m" "tile" "-i" "${config.stylix.image}"
            spawn-at-startup "sleep" "0.2;" "${getExe pkgs.niri-unstable}" "msg" "move-workspace-to-monitor-left"
            animations {
              off
            }
            hotkey-overlay {
              skip-at-startup
            }
            cursor {
              xcursor-theme "catppuccin-mocha-pink-cursors"
              xcursor-size 24
            }
            window-rule {
              open-focused true
            }
          '';
        in
        {
          default_session = {
            command = concatStringsSep " " [
              "${pkgs.dbus}/bin/dbus-run-session --"
              "${getExe pkgs.niri-unstable} -c ${niri-logincfg} --"
              "${getExe pkgs.greetd.regreet};"
              "${getExe pkgs.niri-unstable} msg action quit --skip-confirmation"
            ];
            user = "greeter";
          };
          # auto login when /run/greetd.run don't exist
          initial_session = {
            command = "${niri-session}";
            user = "${arcanum.username}";
          };
        };
    };
    systemd.tmpfiles.rules =
      let
        regreet-defaults =
          pkgs.writeText "regreet-defaults.toml" # toml
            ''
              last_user = "${arcanum.username}"

              [user_to_last_sess]
              nyaa = "Niri"
            '';
      in
      [
        # Don't autologin normally, only use it for scripting purpose (example: qemu hook).
        "f /run/greetd.run 0755 root root"
        # hardcode default user session
        # change to /var/lib after https://github.com/rharish101/ReGreet/pull/107
        "C /var/cache/regreet/cache.toml 0640 greeter greeter - ${regreet-defaults}"
      ];

    security.pam.services.greetd.enableGnomeKeyring = true; # unlock gnome keyring
  };
}
