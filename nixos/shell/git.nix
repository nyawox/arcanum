{
  pkgs,
  arcanum,
  ...
}:
{
  homeConfig = {
    home.file.".ssh/id_ed25519_git.pub".text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGwaALhLXKMZlWj1LDfnbz6+mc7OrButZi4v6xEkO25b
    '';
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      userName = "nyawox";
      userEmail = "git@${arcanum.domain}";
      lfs.enable = true;
      diff-so-fancy.enable = true;
      signing = {
        key = "~/.ssh/id_ed25519_git.pub"; # requires bw ssh agent
        signByDefault = true;
      };
      extraConfig = {
        gpg.format = "ssh";
        push.autoSetupRemote = true;
        pull.rebase = true;
        credential.helper = "libsecret"; # required for obsidian-git plugin
        init.defaultBranch = "main";
        core.symlinks = false;
        transfer.fsckobjects = true;
        fetch.fsckobjects = true;
        receive.fsckobjects = true;
      };
    };
  };
}
