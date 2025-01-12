{
  arcanum,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  magit-editor = pkgs.writeShellScriptBin "magit-editor" ''
    #!/usr/bin/env bash
    # most likely .git/COMMIT_EDITMSG
    export commitmsg="$1"
    emacsclient -nw --eval "(progn\
      (switch-to-buffer (eat-make \"git-editor\" \"hx\" nil \"$commitmsg\"))\
      (with-current-buffer \"*git-editor*\"\
        (evil-local-mode -1))\
      (set-process-sentinel (get-buffer-process \"*git-editor*\")\
        (lambda (proc event)\
          (let ((exit-code (process-exit-status proc)))\
            (kill-buffer \"*git-editor*\")\
            (dolist (client server-clients)\
              (server-delete-client client))\
            (server-edit exit-code)))))"
     exit $?
  '';
in
{
  homeImports = lib.singleton inputs.nix-doom-emacs-unstraightened.hmModule;
  homeConfig = {
    programs.doom-emacs = {
      enable = true;
      doomDir = "${arcanum.configPath}/shell/magit";
    };
    home.packages = [ magit-editor ];
    services.emacs.enable = true;
    programs.nushell.shellAliases = {
      magit = "with-env { TERM: xterm-direct} {emacsclient -nw --eval '(magit-status)'}";
      mg = "magit";
    };
  };
}
