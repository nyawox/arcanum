;; Appearance
(setq doom-theme 'catppuccin
      ;; font size in point(pt)
      doom-font (font-spec :family "Spleen" :size 12)
      doom-variable-pitch-font (font-spec :family "SFProDisplay" :size 8))

(load-theme 'catppuccin t t)
(setq catppuccin-flavor 'mocha)
(catppuccin-reload)

;; replace ; and : to make colon commands easier, I only use magit anyways
(map! :n ";" 'evil-ex)
(map! :n ":" 'evil-repeat-find-char)
;; don't use emacs to edit files, only for rebasing
(use-package! eat)
(setq magit-with-editor-envvar "GIT_SEQUENCE_EDITOR")
(setenv "GIT_EDITOR" "magit-editor")
