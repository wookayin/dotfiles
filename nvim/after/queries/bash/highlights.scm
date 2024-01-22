;; extends
; see $VIMPLUG/nvim-treesitter/queries/bash/highlights.scm

; $(subcommand ...) <- do NOT highlight as string (red)
(command) @command

; In addition to @variable.parameter highlight,
; we mark as @variable.parameter.flag for CLI "--options" or "--flag"
(command
  argument: [
             (word) @variable.parameter.flag
             (concatenation (word) @variable.parameter.flag)
             ]
  (#lua-match? @variable.parameter.flag "^%-%-?%w+"))
