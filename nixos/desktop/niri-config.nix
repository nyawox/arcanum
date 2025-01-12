{
  pkgs,
  lib,
  config,
  arcanum,
  ...
}:
with lib;
let
  login-sound = pkgs.fetchurl {
    name = "login-sound-utopia";
    url = "https://archive.org/download/Win95-audio-media/Windows%2095%20audio%20media/Utopia%20Windows%20Start.wav";
    sha256 = "1vb0czp5v4qqls0wfx4fqw9gfpa0xxfzaxn8anqazk01avchwiy5";
  };
  binds =
    {
      suffixes,
      prefixes,
      substitutions ? { },
    }:
    let
      replacer = replaceStrings (attrNames substitutions) (attrValues substitutions);
      format =
        prefix: suffix:
        let
          actual-suffix =
            if isList suffix.action then
              {
                action = head suffix.action;
                args = tail suffix.action;
              }
            else
              {
                inherit (suffix) action;
                args = [ ];
              };

          action = replacer "${prefix.action}-${actual-suffix.action}";
        in
        {
          name = "${prefix.key}+${suffix.key}";
          value.action.${action} = actual-suffix.args;
        };
      pairs =
        attrs: fn:
        concatMap (
          key:
          fn {
            inherit key;
            action = attrs.${key};
          }
        ) (attrNames attrs);
    in
    listToAttrs (pairs prefixes (prefix: pairs suffixes (suffix: [ (format prefix suffix) ])));
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
        gsettings set $gnome_schema icon-theme '${arcanum.homeCfg.stylix.iconTheme.dark}'
        gsettings set $gnome_schema cursor-theme '${config.stylix.cursor.name}'
        gsettings set $gnome_schema font-name '${config.stylix.fonts.serif.name} ${toString config.stylix.fonts.sizes.desktop}'
        gsettings set $gnome_schema color-scheme prefer-dark
      '';
  };
in
{
  homeConfig = {
    home.packages = with pkgs; [
      qt5.qtwayland
      qt6.qtwayland
      qt6ct
      xdg-user-dirs
      pamixer
    ];
    programs.niri.settings = {
      cursor = {
        theme = config.stylix.cursor.name;
        inherit (config.stylix.cursor) size;
      };
      input = {
        keyboard.xkb.layout = "us";
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
        warp-mouse-to-focus = true;
        mouse.accel-speed = 0.0;
        touchpad = {
          tap = true;
          dwt = true;
          accel-profile = "adaptive";
          accel-speed = 0.0;
          click-method = "clickfinger";
          natural-scroll = true;
          scroll-method = "two-finger";
        };
      };
      layout = {
        gaps = 14;
        struts.left = 10;
        struts.right = 10;
        border.enable = false;
        focus-ring = {
          enable = true;
          active.color = "rgb(243 139 168)";
          inactive.color = "rgb(24 24 37)";
        };
      };
      animations =
        let
          butter = {
            spring = {
              damping-ratio = 0.75;
              epsilon = 1.0e-4;
              stiffness = 400;
            };
          };
          smooth = {
            spring = {
              damping-ratio = 0.58;
              epsilon = 1.0e-4;
              stiffness = 735;
            };
          };
        in
        {
          slowdown = 2.5;
          horizontal-view-movement = butter;
          window-movement = butter;
          workspace-switch = butter;
          window-open = smooth;
          window-close = smooth;
          screenshot-ui-open = smooth;
        };
      window-rules =
        let
          opacity = {
            opacity = config.stylix.opacity.applications;
            draw-border-with-background = false;
          };
        in
        [
          {
            # rounded corners
            geometry-corner-radius = {
              bottom-left = 18.0;
              bottom-right = 18.0;
              top-left = 18.0;
              top-right = 18.0;
            };
            clip-to-geometry = true;
          }
          {
            matches = singleton {
              app-id = "foot";
            };
            min-width = 500;
          }
          (
            {
              matches = [
                { app-id = "firefox"; }
                { app-id = "vesktop"; }
                { app-id = "org.gnome.Nautilus"; }
                { app-id = "org.telegram.desktop"; }
                { app-id = "xdg-desktop-portal-gtk"; }
                { app-id = "gpu-screen-recorder-gtk"; }
                { app-id = "uget-gtk"; }
                { app-id = "pavucontrol"; }
                { app-id = "lutris"; }
                { app-id = ".blueman-manager-wrapped"; }
                { app-id = "obsidian"; }
                # {title = "beta.music.apple.com";}
              ];
              excludes = singleton {
                app-id = "org.telegram.desktop";
                title = "Media viewer";
              };
            }
            // opacity
          )
          {
            matches = [
              {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              }
            ];
            open-floating = true;
            open-focused = false;
          }
          {
            matches = [
              { app-id = "^Bitwarden$"; }
              { app-id = "^org\.gnome\.World\.Secrets$"; }
              { app-id = "^polkit-gnome-authentication-agent-1$"; }
            ];
            max-width = 800;
            max-height = 800;
            open-floating = true;
            block-out-from = "screencast";
          }
        ];
      environment = {
        # fcitx
        INPUT_METHOD = "fcitx5";
        IMSETTINGS_MODULE = "fcitx5";
        XMODIFIERS = "@im=fcitx";
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        # force wayland
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1"; # Disables window decorations on Qt applications
        GDK_BACKEND = "wayland,x11";
        GTK_THEME = arcanum.homeCfg.gtk.theme.name;
      };
      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;
      screenshot-path = "/home/${arcanum.username}/Pictures/screenshot-%Y-%m-%d-%H-%M-%S.png";
      spawn-at-startup =
        let
          mkCmd = cmd: if builtins.isList cmd then { command = cmd; } else { command = singleton cmd; };
        in
        map mkCmd [
          "${configure-gtk}/bin/configure-gtk"
          [
            "${pkgs.pulseaudio}/bin/paplay"
            "${login-sound}"
          ]
          [
            "${getExe pkgs.swaybg}"
            "-m"
            "tile"
            "-i"
            "${config.stylix.image}"
          ]
          "${getExe pkgs.swaynotificationcenter}"
          "${getExe pkgs.waybar}"
          # Only fcitx5 installed via the NixOS module contains mozc, it must be in the PATH.
          # -r replaces current instance
          [
            "fcitx5"
            "-r"
            "-d"
          ]
          [
            "dbus-update-activation-environment"
            "--all"
            "--systemd"
          ]
          "systemctl --user reset-failed waybar.service"
          "systemctl --user reset-failed polkit-gnome-authentication-agent-1.service"
          "${getExe pkgs.bitwardenapp}"
        ];
      outputs = {
        "DP-4" = {
          scale = 0.75;
          position.x = 0;
          position.y = 0;
        };
        "DP-7" = {
          scale = 0.75;
          position.x = 2560;
          position.y = 0;
        };
        "eDP-1".scale = 0.75;
      };
      binds =
        with arcanum.homeCfg.lib.niri.actions;
        let
          sh = spawn "sh" "-c";
        in
        lib.attrsets.mergeAttrsList [
          {
            "Mod+E".action = spawn "${getExe pkgs.foot}";
            "Mod+I".action = spawn "${getExe pkgs.fuzzel}";
            "Mod+A".action = sh "${getExe pkgs.nautilus} --new-window";
            "Mod+Y".action = sh "${getExe pkgs.swaynotificationcenter}-client -t -sw";
            "Mod+W".action = sh "killall .waybar-wrapped && waybar";
            "Mod+Escape".action = sh "loginctl lock-session";

            "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
            "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

            "XF86MonBrightnessUp".action = sh "brightnessctl set 10%+";
            "XF86MonBrightnessDown".action = sh "brightnessctl set 10%-";

            "Mod+Q".action = close-window;
          }
          (binds {
            suffixes = {
              "Left" = "column-left";
              "Down" = "window-or-workspace-down";
              "Up" = "window-or-workspace-up";
              "Right" = "column-right";
            };
            prefixes = {
              "Mod" = "focus";
              "Mod+Shift" = "move";
              "Mod+Ctrl" = "focus-monitor";
              "Mod+Ctrl+Shift" = "move-window-to-monitor";
            };
            substitutions = {
              "monitor-column" = "monitor";
              "monitor-window-or-workspace" = "monitor";
              "move-window-or-workspace-down" = "move-window-down-or-to-workspace-down";
              "move-window-or-workspace-up" = "move-window-up-or-to-workspace-up";
            };
          })
          (binds {
            suffixes."Home" = "first";
            suffixes."End" = "last";
            prefixes."Mod" = "focus-column";
            prefixes."Mod+Ctrl" = "move-column-to";
          })
          (binds {
            suffixes = builtins.listToAttrs (
              map (n: {
                name = toString n;
                value = [
                  "workspace"
                  n
                ];
              }) (range 1 9)
            );
            prefixes = {
              "Mod" = "focus";
              "Mod+Ctrl" = "move-window-to";
            };
          })
          {
            "Mod+Comma".action = consume-window-into-column;
            "Mod+Period".action = expel-window-from-column;

            "Mod+R".action = switch-preset-column-width;
            "Mod+F".action = maximize-column;
            "Mod+Shift+F".action = fullscreen-window;
            "Mod+C".action = center-column;

            "Mod+Minus".action = set-column-width "-10%";
            "Mod+Kp_Add".action = set-column-width "+10%";
            "Mod+Shift+Minus".action = set-window-height "-10%";
            "Mod+Shift+Kp_Add".action = set-window-height "+10%";
            "Mod+WheelScrollDown" = {
              cooldown-ms = 150;
              action = focus-workspace-down;
            };
            "Mod+WheelScrollUp" = {
              cooldown-ms = 150;
              action = focus-workspace-up;
            };
            "Mod+Shift+WheelScrollDown" = {
              cooldown-ms = 150;
              action = move-column-to-workspace-down;
            };
            "Mod+Shift+WheelScrollUp" = {
              cooldown-ms = 150;
              action = move-column-to-workspace-up;
            };

            "Print".action = screenshot;
            "Shift+Print".action = screenshot-screen;

            "Mod+Shift+E".action = quit;
            "Mod+Shift+P".action = power-off-monitors;

            "Mod+Shift+Ctrl+T".action = toggle-debug-tint;
          }
        ];
    };
  };
}
