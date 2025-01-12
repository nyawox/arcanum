{
  cfg,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
{
  options.ide = mkEnableOption "Enable magit, zellij, yazi to replicate IDE experience";
  content.modules.shell = {
    zellij.enable = mkIf cfg.ide true;
    yazi.enable = mkIf cfg.ide true;
    magit.enable = mkIf cfg.ide true;
  };
  homeConfig = {
    programs.helix = {
      enable = true;
      extraPackages = with pkgs; [
        markdown-oxide # markdown language server
        inputs.latest.legacyPackages.${pkgs.system}.nixfmt-rfc-style
        tree-sitter-kdl
        python3Packages.python-lsp-server
        rust-analyzer
      ];
      package = inputs.helix.packages.${pkgs.system}.helix;
      defaultEditor = true;
      settings = {
        theme = "catppuccin_mocha_transparent";
        editor = {
          auto-completion = true;
          bufferline = "multiple"; # Show currently open buffers when multiple exists
          true-color = true;
          color-modes = true;
          line-number = "relative";
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          icons = {
            vcs.enabled = true;
            mime.enabled = true;
          };
          lsp = {
            auto-signature-help = true;
            display-messages = true;
          };
          indent-guides = {
            character = "│";
            render = true;
          };
          statusline = {
            left = [
              "mode"
              "spinner"
              "selections"
              "register"
              "position"
            ];
            center = [
              "read-only-indicator"
              "file-name"
              "file-modification-indicator"
            ];
            right = [
              "diagnostics"
              "file-encoding"
              "version-control"
            ];
            separator = "│";
          };
        };
        keys.normal = {
          ";" = "command_mode"; # Replace : with ;
          space = {
            space = "file_picker";
            n = mkIf cfg.ide ":sh zellij action focus-next-pane"; # set focus to file tree
            o = mkIf cfg.ide {
              n = "file_browser";
              N = "file_browser_in_current_buffer_directory";
              # git
              g = ":sh zellij run --name Git -fc -- bash -c \"TERM=xterm-direct emacsclient -nw --eval '(magit-status)'\""; # open magit in floating pane
              # terminal
              t = ":sh zellij action new-pane -c -d down -- bash -c \"for _ in {1..6}; do zellij action resize decrease up; done; nu\"";
              # help
              h = ":sh zellij action new-pane -fp file:~/.config/zellij/plugins/zellij_forgot.wasm";
            };
          };
        };
        keys.insert = {
          # "C-h" = "delete_word_backward"; # Ctrl-bspc
          "C-x" = "no_op";
          "C-l" = "completion"; # mnemonic for lsp
        };
      };
      languages = {
        language = [
          {
            name = "python";
            language-servers = [
              "pylsp"
            ];
          }
          {
            name = "nix";
            auto-format = true;
            language-servers = [
              "nixd"
            ];
            formatter.command = "${getExe inputs.latest.legacyPackages.${pkgs.system}.nixfmt-rfc-style}";
          }
          {
            name = "typescript";
            language-servers = [
              "typescript"
            ];
          }
          {
            name = "javascript";
            language-servers = [
              "typescript"
            ];
          }
          {
            name = "rust";
            auto-format = true;
            language-servers = [
              "rust-analyzer"
            ];
            formatter.command = "rustfmt";
          }
          {
            name = "kdl";
            scope = "source.kdl";
            injection-regex = "kdl";
            file-types = [ "kdl" ];
            roots = [ ];
            comment-token = "//";
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
        ];
        language-server.nixd.command = "${getExe pkgs.nixd}";
      };
      themes = {
        catppuccin_mocha_transparent = {
          "inherits" = "catppuccin_mocha";
          "ui.background" = { };
        };
      };
    };
  };
}
