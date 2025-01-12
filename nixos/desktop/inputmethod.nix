{
  lib,
  pkgs,
  ...
}:
with lib;
{
  content = {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-mozc
          fcitx5-gtk
          libsForQt5.fcitx5-qt
          catppuccin-fcitx5
        ];
        waylandFrontend = true;
      };
    };
  };
  userPersist.directories = [
    ".config/fcitx5"
    ".config/fcitx"
  ];
  homeConfig = {
    xdg.configFile = {
      "fcitx5/conf/classicui.conf".text = # conf
        ''
          # Vertical Candidate List
          Vertical Candidate List=False
          # Use mouse wheel to go to prev or next page
          WheelForPaging=True
          # Font
          Font="MigMix 1P 14"
          # Menu Font
          MenuFont="MigMix 1P 14"
          # Tray Font
          TrayFont="MigMix 1P Bold 14"
          # Tray Label Outline Color
          TrayOutlineColor=#000000
          # Tray Label Text Color
          TrayTextColor=#ffffff
          # Prefer Text Icon
          PreferTextIcon=False
          # Show Layout Name In Icon
          ShowLayoutNameInIcon=True
          # Use input method language to display text
          UseInputMethodLanguageToDisplayText=True
          # Theme
          Theme=catppuccin-latte-pink
          # Dark Theme
          DarkTheme=catppuccin-mocha-pink
          # Follow system light/dark color scheme
          UseDarkTheme=True
          # Follow system accent color if it is supported by theme and desktop
          UseAccentColor=True
          # Use Per Screen DPI on X11
          PerScreenDPI=False
          # Force font DPI on Wayland
          ForceWaylandDPI=0
          # Enable fractional scale under Wayland
          EnableFractionalScale=True
        '';
      # mostly default
      "fcitx5/config".text = # conf
        ''
          [Hotkey]
          # Enumerate when press trigger key repeatedly
          EnumerateWithTriggerKeys=True
          # Enumerate Input Method Forward
          EnumerateForwardKeys=
          # Enumerate Input Method Backward
          EnumerateBackwardKeys=
          # Skip first input method while enumerating
          EnumerateSkipFirst=False

          [Hotkey/TriggerKeys]
          0=Zenkaku_Hankaku
          1=Hangul

          [Hotkey/AltTriggerKeys]
          0=Shift_L

          [Hotkey/EnumerateGroupForwardKeys]
          0=Super+space

          [Hotkey/EnumerateGroupBackwardKeys]
          0=Shift+Super+space

          [Hotkey/ActivateKeys]
          0=Hangul_Hanja

          [Hotkey/DeactivateKeys]
          0=Hangul_Romaja

          [Hotkey/PrevPage]
          0=Up

          [Hotkey/NextPage]
          0=Down

          [Hotkey/PrevCandidate]
          0=Shift+Tab

          [Hotkey/NextCandidate]
          0=Tab

          [Hotkey/TogglePreedit]
          0=Control+Alt+P

          [Behavior]
          # Active By Default
          ActiveByDefault=False
          # Reset state on Focus In
          resetStateWhenFocusIn=No
          # Share Input State
          ShareInputState=No
          # Show preedit in application
          PreeditEnabledByDefault=True
          # Show Input Method Information when switch input method
          ShowInputMethodInformation=True
          # Show Input Method Information when changing focus
          showInputMethodInformationWhenFocusIn=False
          # Show compact input method information
          CompactInputMethodInformation=True
          # Show first input method information
          ShowFirstInputMethodInformation=True
          # Default page size
          DefaultPageSize=5
          # Override Xkb Option
          OverrideXkbOption=False
          # Custom Xkb Option
          CustomXkbOption=
          # Force Enabled Addons
          EnabledAddons=
          # Force Disabled Addons
          DisabledAddons=
          # Preload input method to be used by default
          PreloadInputMethod=True
          # Allow input method in the password field
          AllowInputMethodForPassword=False
          # Show preedit text when typing password
          ShowPreeditForPassword=False
          # Interval of saving user data in minutes
          AutoSavePeriod=30

        '';
    };
  };
}
