_: {
  homeConfig = {
    programs.fzf.enable = true;
    programs.nushell.environmentVariables = {
      FZF_DEFAULT_OPTS = "
        --color bg+:#313244
        --color bg:#1e1e2e
        --color spinner:#f5e0dc
        --color hl:#f38ba8
        --color fg:#cdd6f4
        --color header:#f38ba8
        --color info:#cba6f7
        --color pointer:#f5e0dc
        --color marker:#b4befe
        --color fg+:#cdd6f4
        --color prompt:#cba6f7
        --color hl+:#f38ba8
        --color selected-bg:#45475a
        --multi
        --border rounded
        --prompt 'λ '
        --walker-skip .git,node_modules,target,.direnv,.Trash-1000,.deploy-gc,gcroot
      ";
    };
  };
}
