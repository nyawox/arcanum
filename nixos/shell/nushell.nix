{
  lib,
  pkgs,
  ...
}:
with lib;
let
  nuScripts = "${pkgs.nu_scripts}/share/nu_scripts";
  mkCompletions =
    names:
    concatStringsSep "\n" (
      map (name: "source \"${nuScripts}/custom-completions/${name}/${name}-completions.nu\"") names
    );
in
{
  content = {
    modules.shell = {
      carapace.enable = true;
      skim.enable = true;
      starship.enable = true;
      zoxide.enable = true;
      direnv.enable = true;
    };
  };
  homeConfig = {
    home.packages = with pkgs; [
      lsof
      # must be in PATH
      nu_plugin_clipboard
      nu_plugin_desktop_notifications
      nu_plugin_emoji
      nu_plugin_file
    ];
    programs.nushell = {
      enable = true;
      plugins = with pkgs; [
        nushellPlugins.gstat
        nu_plugin_audio_hook
        nu_plugin_clipboard
        nu_plugin_desktop_notifications
        # nu_plugin_dns
        nu_plugin_emoji
        nu_plugin_file
      ];
      extraConfig =
        # nu
        ''

          def lsd [] { ls | sort-by type name -i | grid -c }

          def psn [name] {
            ps | where name =~ $name
          }

          ${mkCompletions [
            "git"
            "adb"
            "curl"
            "cargo"
            "cargo-make"
            "btm"
            "bat"
            "zellij"
            "tar"
            "rustup"
            "rg"
            "npm"
            "nix"
            "man"
            "make"
            "less"
            "just"
            "docker"
            "fastboot"
          ]}

          # ns -> nix search nixpkgs
          source "${nuScripts}/modules/nix/nix.nu"
          # fastfetch alternative
          use "${nuScripts}/modules/nix/nufetch.nu"
          # wrap `lsof` and `ps` and return a nice table
          # requires lsof package
          use "${nuScripts}/modules/network/sockets/sockets.nu"
          # convenient function to extract all most archive extensions
          # requires binutils for `ar x` command (deb file)
          source "${nuScripts}/modules/data_extraction/ultimate_extractor.nu"
          # ssh completion and more
          use "${nuScripts}/modules/network/ssh.nu";
        '';
      extraEnv =
        # nu
        ''
          use "${nuScripts}/themes/nu-themes/catppuccin-mocha.nu"

          # mostly copy paste from nushell.sh/cookbook
          let carapace_completer = {|spans: list<string>|
              carapace $spans.0 nushell ...$spans
              | from json
              | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
          }
          let fish_completer = {|spans|
              ${getExe pkgs.fish} --command $'complete "--do-complete=($spans | str join " ")"'
              | from tsv --flexible --noheaders --no-infer
              | rename value description
          }
          let zoxide_completer = {|spans|
              $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
          }
          let external_completer = {|spans|
              let expanded_alias = scope aliases # alias completions
              | where name == $spans.0
              | get -i 0.expansion

              let spans = if $expanded_alias != null {
                  $spans
                  | skip 1
                  | prepend ($expanded_alias | split row ' ' | take 1)
              } else {
                  $spans
              }

              match $spans.0 { # comments from docs
                # carapace completions are incorrect for nu
                nu => $fish_completer
                # fish completes commits and branch names in a nicer way
                git => $fish_completer
                # # carapace doesn't have completions for asdf
                # asdf => $fish_completer
                # use zoxide completions for zoxide commands
                __zoxide_z | __zoxide_zi => $zoxide_completer
                _ => $carapace_completer
              } | do $in $spans
          }

          $env.config = {
            show_banner: false,
            color_config: (catppuccin-mocha),
            completions: {
              case_sensitive: false,
              quick: true,
              partial: true,
              algorithm: "fuzzy",
              external: {
                enable: true,
                completer: $external_completer
              }
            },
            table: {
              mode: rounded
            }
            hooks: {
              command_not_found: {|cmd|
                if (which command-not-found | is-empty) {
                  return (error make {msg: $"Command not found: ($cmd)"})
                }
                command-not-found $cmd
              }
            }
          }
          $env.LS_COLORS = (${getExe pkgs.vivid} generate catppuccin-mocha)
        '';
      shellAliases = {
        vi = "hx";
        vim = "hx";
        nano = "hx";
        nix-prefetch-github = "nix-prefetch-github --nix";
        ll = "ls -l";
        c = "clear";
        do = "sudo";
        lix = "nix";
        writeusb = "sudo dd bs=4M oflag=sync status=progress";
      };
    };
  };
}
