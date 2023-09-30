;; extends

; Additional treesitter highlight for python
; see $VIMPLUG/nvim-treesitter/queries/python/highlights.scm



; Use a highlight group for test function/method definitions
((class_definition
  body: (block
          (function_definition
            name: (identifier) @method.test)))
 (#lua-match? @method.test "^test_"))

((function_definition
  name: (identifier) @function.test)
 (#lua-match? @function.test "^test_"))


; Highlight multi-line strings that start with a shebang
; see python/injections.scm
(((string_content) @none.nested)
 (#match? @none.nested "^#!/bin/bash\n"))
(((string_content) @none.nested)
 (#lua-match? @none.nested "^[%s]*#!/usr/bin/env python[%d.]*\n"))
