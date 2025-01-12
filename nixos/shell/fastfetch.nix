{
  lib,
  pkgs,
  arcanum,
  ...
}:
{
  homeConfig = {
    home.packages = lib.singleton pkgs.fastfetch;
    programs.nushell.shellAliases.fetch = "fastfetch";
    xdg.configFile."fastfetch/nixos.sixel".source = "${arcanum.configPath}/shell/fastfetch/nixos.sixel";
    xdg.configFile."fastfetch/config.jsonc".text =
      # jsonc
      ''
        {
          "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
          "logo": {
            "source": "~/.config/fastfetch/nixos.sixel",
            "type": "raw",
            "width": 45,
            "height": 18,
            "padding": {
              "top": 2,
            },
          },
          "modules": [
            "title",
            "separator",
            {
              "type": "os",
              "format": "{3} {12}"
            },
            {
              "type": "host",
              "format": "{/2}{-}{/}{2}{?3} {3}{?}"
            },
            "kernel",
            "uptime",
            "packages",
            "shell",
            {
              "type": "display",
              "key": "Resolution",
              "compactType": "original"
            },
            {
              "type": "de",
              "format": "{2} {3}"
            },
            "wm",
            "wmtheme",
            {
              "type": "theme",
              "format": "{?1}{1}{?3} {3}{?} [Plasma], {?}{7}"
            },
            "icons",
            "terminal",
            {
              "type": "terminalfont",
              "format": "{/2}{-}{/}{2}{?3} {3}{?}"
            },
            "cpu",
            {
              "type": "gpu",
              "forceVulkan": true
            },
            {
              "type": "memory",
              "format": "{/1}{-}{/}{/2}{-}{/}{} / {}"
            },
            "break",
            "colors"
          ]
        }
      '';
  };
}
