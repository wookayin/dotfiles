;; extends

; Injection syntax requires nvim-treesitter 0.10.x and neovim 0.10.x
; see also python/highlights.scm for highlight fix

; Highlight multi-line strings that start with a shebang
; e.g. '''#!/bin/bash ...'''

(((string_content) @injection.content)
 (#match? @injection.content "^#!/bin/bash\n")
 (#set! injection.language "bash")
 (#set! injection.include-children)
)

(((string_content) @injection.content)
 (#lua-match? @injection.content "^[%s]*#!/usr/bin/env python[%d.]*\n")
 (#set! injection.language "python")
 (#set! injection.include-children)
)

; python docstrings
; see https://github.com/nvim-treesitter/nvim-treesitter/pull/5585
; see queries/python/highlights.scm

(module . (expression_statement (string (string_content) @injection.content)
           (#set! injection.language "comment")
           ))

(class_definition
  body:
    (block
      . (expression_statement (string (string_content) @injection.content)
        (#set! injection.language "comment")
        )))

(function_definition
  body:
    (block
      . (expression_statement (string (string_content) @injection.content)
        (#set! injection.language "comment")
        )))
