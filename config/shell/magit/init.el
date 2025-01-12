;;; init.el -*- lexical-binding: t; -*-

(doom! :input
       japanese

       :completion
       (company +childframe +tng)           ; the ultimate code completion backend
       vertico                              ; the search engine of the future

       :ui
       doom                                 ; what makes DOOM look the way it does
       modeline                             ; snazzy, Atom-inspired modeline, plus API

       :editor
       (evil +everywhere)                   ; come to the dark side, we have cookies

       :emacs
       undo                                 ; persistent, smarter undo for your inevitable mistakes

       :tools
       magit                                ; a git porcelain for Emacs

       :config
       (default +bindings +smartparens))
