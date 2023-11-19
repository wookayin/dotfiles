;; extends
; see $VIMPLUG/nvim-treesitter/queries/bash/highlights.scm

; $(subcommand ...) <- do NOT highlight as string (red)
(command) @command

; In addition to @parameter highlight, we mark as @parameter.flag
; for CLI "--options" or "--flag"
(command
  argument: [
             (word) @parameter.flag
             (concatenation (word) @parameter.flag)
             ]
  (#lua-match? @parameter.flag "^%-%-?%w+"))
