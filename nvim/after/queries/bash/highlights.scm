;; extends
; see $VIMPLUG/nvim-treesitter/queries/bash/highlights.scm

; $(subcommand ...) <- do NOT highlight as string (red)
(command) @command

; Highlight "--flags" in bash commands
; In addition to @variable.parameter highlight,
; we mark as @variable.parameter.flag for CLI "--options" or "--flag"
(command
  argument: [
    (word) @variable.parameter.flag
    (concatenation (word) @variable.parameter.flag)
  ]
  (#lua-match? @variable.parameter.flag "^%-%-?%w+"))

; also in array variables, e.g. cmd=(foo --bar="1" --baz)
(variable_assignment
  (array
    (concatenation
      (word) @none  ; override (concatenation (word) @string), e.g. foobar="?"
    )))
(variable_assignment
  value: (array
    [
      (word) @variable.parameter.flag
      (concatenation (word) @variable.parameter.flag)
    ]
  )
  (#lua-match? @variable.parameter.flag "^%-%-?%w+"))
