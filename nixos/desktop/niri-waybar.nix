_: {
  homeConfig = {
    programs.waybar = {
      enable = true;
      systemd.enable = false;
      settings = [
        {
          output = [
            "DP-4"
            "DP-7"
            "eDP-1"
          ];
          layer = "top"; # Waybar at top layer
          position = "top"; # Waybar position (top|bottom|left|right)
          height = 46; # Waybar height (to be removed for auto height)
          spacing = 5; # Gaps between modules (4px)
          margin-bottom = -11;

          modules-left = [ "niri/workspaces" ];
          modules-center = [ "niri/window" ];
          modules-right = [
            "tray"
            "cpu"
            "memory"
            "battery"
            "pulseaudio"
            "clock"
          ];

          # Modules configuration
          "niri/workspaces" = {
            all-outputs = false;
            format = "{index}";
          };

          "niri/window" = {
            format = "{title}";
            icon = true;
            separate-outputs = true;
            max-length = 90;
          };

          tray = {
            icon-size = 20;
            spacing = 10;
          };

          clock = {
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            interval = 60;
            format = " {:%H:%M}";
            max-length = 25;
          };

          cpu = {
            interval = 1;
            format = "{icon0} {icon1} {icon2} {icon3}";
            format-icons = [
              "▁"
              "▂"
              "▃"
              "▄"
              "▅"
              "▆"
              "▇"
              "█"
            ];
          };

          memory = {
            interval = 10;
            format = " {used:.2f}/{total:.2f}GiB";
          };

          battery = {
            interval = 1;
            states = {
              warning = 50;
              critical = 20;
            };
            format = "{icon} ";
            format-charging = "{icon}  ";
            format-plugged = "";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };

          pulseaudio = {
            scroll-step = 1;
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}%  {format_source}";
            format-bluetooth-muted = "  {format_source}";
            format-muted = " {format_source}";
            format-icons = {
              headphone = "󰋋";
              hands-free = "󰋋";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };
        }
      ];
    };
  };
}
