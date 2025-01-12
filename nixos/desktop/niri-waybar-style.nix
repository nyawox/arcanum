_: {
  homeConfig = {
    programs.waybar.style =
      # css
      ''
        * {
          font-family:
            SF Pro Text,
            Symbols Nerd Font,
            "MigMix 1P",
            "Font Awesome 6 Free";
          font-size: 14pt;
        }

        window#waybar {
          background-color: transparent;
        }

        #workspaces {
          background-color: transparent;
          margin-top: 10px;
          margin-bottom: 10px;
          margin-right: 10px;
          margin-left: 10px;
        }

        #workspaces button {
          box-shadow: rgba(205, 214, 444, 0.116) 3px 3px 7px 3px;
          background-color: #181825;
          border-radius: 10px;
          margin-right: 5px;
          margin-left: 5px;
          padding-top: 3px;
          padding-bottom: 3px;
          padding-right: 10px;
          padding-left: 10px;
          color: #a6adc8;
          font-weight: 700;
        }

        #workspaces button.active {
          box-shadow: rgba(0, 0, 0, 0.288) 3px 3px 7px 3px;
          text-shadow: 0 0 7px rgba(0, 0, 0, 0.377);
          margin-right: 5px;
          margin-left: 5px;
          padding-left: 26px;
          padding-right: 26px;
          background: linear-gradient(
            45deg,
            rgba(203, 166, 247, 1) 0%,
            rgba(245, 194, 231, 1) 43%,
            rgba(242, 205, 205, 1) 80%,
            rgba(235, 160, 172, 1) 100%
          );
          background-size: 300% 300%;
          animation: gradient 2s ease infinite;
          color: #11111b;
          font-weight: 700;
        }

        @keyframes gradient {
          0% {
            background-position: 0% 50%;
          }
          50% {
            background-position: 100% 50%;
          }
          100% {
            background-position: 0% 50%;
          }
        }

        #clock,
        #cpu,
        #memory,
        #battery,
        #pulseaudio,
        #tray,
        #window {
          padding: 0 13px;
          border-radius: 10px;
          box-shadow: rgba(0, 0, 0, 0.116) 3px 3px 7px 3px;
          margin-top: 10px;
          margin-bottom: 10px;
          margin-right: 10px;
        }

        #window {
          background: linear-gradient(
            45deg,
            rgba(166, 227, 161, 1) 0%,
            rgba(148, 226, 213, 1) 26%,
            rgba(137, 220, 235, 1) 65%,
            rgba(116, 199, 236, 1) 100%
          );
          background-size: 300% 300%;
          animation: gradient 2s ease infinite;
          text-shadow: 0 0 7px rgba(0, 0, 0, 0.377);
          font-weight: 500;
          font-size: 16px;
          color: #181825;
        }

        window#waybar.empty #window {
          background: none;
          box-shadow: none;
        }

        #clock {
          background: linear-gradient(
            52deg,
            rgba(245, 194, 231, 1) 0%,
            rgba(203, 166, 247, 1) 64%,
            rgba(180, 190, 254, 1) 100%
          );
          animation: gradient 4s ease infinite;
          margin-right: 26px;
          color: #181825;
          background-size: 300% 300%;
          text-shadow: 0 0 7px rgba(0, 0, 0, 0.377);
          font-size: 16px;
          padding-top: 7px;
          padding-bottom: 7px;
          padding-left: 20px;
          padding-right: 20px;
          font-weight: 500;
        }

        #battery {
          background-color: #fff;
          color: #a6e3a1;
          font-weight: 500;
          font-size: 16px;
          padding-left: 16px;
          padding-right: 16px;
        }

        #battery.charging,
        #battery.plugged {
          background-color: #a6e3a1;
          color: #181825;
        }

        @keyframes blink {
          to {
            background-color: #f9e2af;
            color: #96804e;
          }
        }

        label:focus {
        }

        #cpu {
          background: linear-gradient(
            52deg,
            rgba(137, 220, 235, 1) 0%,
            rgba(116, 199, 236, 1) 32%,
            rgba(137, 180, 250, 1) 72%,
            rgba(180, 190, 254, 1) 100%
          );
          background-size: 300% 300%;
          animation: gradient 4s ease infinite;
          text-shadow: 0 0 7px rgba(0, 0, 0, 0.377);
          color: #181825;
        }

        #memory {
          background: linear-gradient(
            52deg,
            rgba(243, 139, 168, 1) 0%,
            rgba(237, 135, 150, 1) 32%,
            rgba(231, 130, 132, 1) 72%,
            rgba(235, 160, 172, 1) 100%
          );
          color: #181825;
          animation: gradient 4s ease infinite;
          font-size: 16px;
          padding-top: 7px;
          padding-bottom: 7px;
          padding-left: 20px;
          padding-right: 20px;
          font-weight: 500;
        }

        #pulseaudio {
          background: linear-gradient(
            52deg,
            rgba(250, 179, 135, 1) 0%,
            rgba(239, 159, 188, 1) 100%
          );
          animation: gradient 4s ease infinite;
          color: #181825;
          font-size: 16px;
          padding-top: 7px;
          padding-bottom: 7px;
          padding-left: 20px;
          padding-right: 20px;
          font-weight: 500;
        }

        #pulseaudio.muted {
          background-color: #90b1b1;
          padding-top: 7px;
          padding-bottom: 7px;
          padding-left: 20px;
          padding-right: 20px;
          font-weight: 500;
        }

        #tray {
          background-color: #313244;
        }

        #tray > .passive {
          -gtk-icon-effect: dim;
        }

        #tray > .needs-attention {
          -gtk-icon-effect: highlight;
          background-color: #eb4d4b;
        }
      '';
  };
}
