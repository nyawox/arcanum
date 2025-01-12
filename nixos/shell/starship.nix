{
  lib,
  pkgs,
  ...
}:
{
  homeConfig.programs.starship =
    let
      variant = "mocha"; # One of `latte`, `frappe`, `macchiato`, or `mocha`
      catppuccin = pkgs.catppuccin.override {
        accent = "pink";
        inherit variant;
      };
    in
    {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = true;
        format = lib.concatStrings [ "$all" ];

        directory.style = "bold lavender";
        character = {
          success_symbol = "[󰘧](mauve)";
          error_symbol = "[X](red)";
          vimcmd_symbol = "[](green)";
        };

        git_status = {
          style = "maroon";
          ahead = "⇡ ";
          behind = "⇣ ";
          diverged = "⇕ ";
        };

        palette = "catppuccin_${variant}";
      } // lib.importTOML "${catppuccin}/starship/${variant}.toml";
    };
}
