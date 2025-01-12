# thanks to https://github.com/luccahuguet/yazelix/
{
  pkgs,
  arcanum,
  inputs,
  ...
}:
let
  yazi-plugins = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "plugins";
    rev = "600614a9dc59a12a63721738498c5541c7923873";
    hash = "sha256-mQkivPt9tOXom78jgvSwveF/8SD8M2XCXxGY8oijl+o=";
  };
in
{
  homeConfig = {
    programs.zellij = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      enableZshIntegration = false;
    };
    programs.nushell.shellAliases = {
      he = "zellij -s $'($env.PWD | path basename)-(random int)' --new-session-with-layout /home/${arcanum.username}/.config/zellij/layouts/helix.kdl";
    };

    xdg.configFile = {
      "zellij/config.kdl".text =
        builtins.readFile "${arcanum.configPath}/shell/zellij/config.kdl"
        + ''
          theme "catppuccin-mocha"
          on_force_close "quit"
          simplified_ui true
          pane_frames true
          ui {
            pane_frames {
              hide_session_name true
              rounded_corners true
            }
          }
        '';

      "zellij/plugins/zellij_forgot.wasm".source = pkgs.fetchurl {
        url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.1/zellij_forgot.wasm";
        sha256 = "1pxwy5ld3affpzf20i1zvn3am12vs6jwp06wbshw4g1xw8drj4ch";
      };

      "zellij/plugins/zjstatus.wasm".source = "${
        inputs.zjstatus.packages.${pkgs.system}.default
      }/bin/zjstatus.wasm";

      "zellij/yazi/keymap.toml".text =
        # toml
        ''
          # keymap.toml
          [[manager.prepend_keymap]]
          desc = "Smart filter"
          on = ["F"]
          run = "plugin smart-filter"

          [[manager.prepend_keymap]]
          desc = "Jump to a file/directory via fzf"
          on = ["f"]
          run = "plugin fzf"

          [[manager.prepend_keymap]]
          desc = "Search files by content via ripgrep"
          on = ["z"]
          run = "search --via=rg"

          [[manager.prepend_keymap]]
          desc = "Jump to a directory via zoxide"
          on = ["j"]
          run = "plugin zoxide"
        '';

      "zellij/yazi/yazi.toml".text =
        # toml
        ''
          # yazi.toml

          [manager]
          ratio = [0, 4, 0]

          [opener]
          edit = [
            { run = 'nu ~/.config/zellij/yazi/open_file.nu "$1"', desc = "Open File in a new pane" },
          ]
        '';
      "zellij/yazi/plugins/no-status.yazi".source = "${yazi-plugins}/no-status.yazi";
      "zellij/yazi/plugins/smart-filter.yazi".source = "${yazi-plugins}/smart-filter.yazi";
      "zellij/yazi/theme.toml".source =
        "${pkgs.catppuccin-yazi}/themes/mocha/catppuccin-mocha-mauve.toml";
      "zellij/yazi/Catppuccin-mocha.tmTheme".source =
        "${pkgs.catppuccin-bat}/themes/Catppuccin Mocha.tmTheme";

      "zellij/yazi/init.lua".text =
        # lua
        ''
          require("no-status"):setup()
        '';

      "zellij/layouts/helix.kdl".source = "${arcanum.configPath}/shell/zellij/helix.kdl";
      "zellij/layouts/helix.swap.kdl".source = "${arcanum.configPath}/shell/zellij/helix.swap.kdl";

      "zellij/yazi/open_file.nu".text =
        # nu
        ''
          #!/usr/bin/env nu

          export def is_hx_running [list_clients_output: string] {
              let cmd = $list_clients_output | str trim | str downcase

              # Split the command into parts
              let parts = $cmd | split row " "

              # Check if any part ends with 'hx', is 'hx', ends with '.hx-wrapped' or '.hx-wrapped_'
              let has_hx = ($parts | any {|part| 
                  ($part | str ends-with "/hx") or ($part | str ends-with "/.hx-wrapped") or ($part | str ends-with "/.hx-wrapped_")
              })
              let is_hx = ($parts | any {|part| 
                  ($part == "hx") or ($part == ".hx-wrapped") or ($part == ".hx-wrapped_")
              })
              let has_or_is_hx = $has_hx or $is_hx

              # Find the position of 'hx' or '.hx-wrapped' variants in the parts
              let hx_positions = ($parts | enumerate | where {|x| 
                  ($x.item == "hx") or ($x.item == ".hx-wrapped") or ($x.item == ".hx-wrapped_") or ($x.item | str ends-with "/hx") or ($x.item | str ends-with "/.hx-wrapped") or ($x.item | str ends-with "/.hx-wrapped_")
              } | get index)

              # Check if 'hx' or variants are the first part or right after a path
              let is_hx_at_start = if ($hx_positions | is-empty) {
                  false
              } else {
                  let hx_position = $hx_positions.0
                  $hx_position == 0 or ($hx_position > 0 and ($parts | get ($hx_position - 1) | str ends-with "/"))
              }

              let result = $has_or_is_hx and $is_hx_at_start

              # Debug information
              print $"input: list_clients_output = ($list_clients_output)"
              print $"treated input: cmd = ($cmd)"
              print $"  parts: ($parts)"
              print $"  has_hx: ($has_hx)"
              print $"  is_hx: ($is_hx)"
              print $"  has_or_is_hx: ($has_or_is_hx)"
              print $"  hx_positions: ($hx_positions)"
              print $"  is_hx_at_start: ($is_hx_at_start)"
              print $"  Final result: ($result)"
              print ""

              $result
          }

          def main [file_path: path] {
              # Move focus to the next pane
              zellij action focus-next-pane

              # Store the second line of the zellij clients list in a variable
              let list_clients_output = (zellij action list-clients | lines | get 1)

              # Parse the output to remove the first two words and extract the rest
              let running_command = $list_clients_output
                  | parse --regex '\w+\s+\w+\s+(?<rest>.*)'  # Use regex to match two words and capture the remaining text as 'rest'
                  | get rest  # Retrieve the captured 'rest' part, which is everything after the first two words
                  | to text

              # Check if the command running in the current pane is hx
              if (is_hx_running $running_command) {
                  # The current pane is running hx, use zellij actions to open the file
                  zellij action write 27
                  zellij action write-chars $":open \"($file_path)\""
                  zellij action write 13
              } else {
                  # The current pane is not running hx, so open hx in a new pane
                  zellij action new-pane
                  sleep 0.5sec

                  # Determine the working directory
                  let working_dir = if ($file_path | path exists) and ($file_path | path type) == "dir" {
                      $file_path
                  } else {
                      $file_path | path dirname
                  }

                  # Change to the working directory
                  zellij action write-chars $"cd ($working_dir)"
                  zellij action write 13
                  sleep 0.2sec

                  # Open Helix
                  zellij action write-chars $"hx ($file_path)"
                  sleep 0.1sec
                  zellij action write 13
                  sleep 0.1sec
              }
          }
        '';
    };
  };
}
