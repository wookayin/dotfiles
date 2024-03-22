;; extends

; Fold [[ ... ]] strings
(string
  "[[" (string_content) "]]"
) @fold


; 🚧 Fold a maximally consecutive lines of luadoc comments.
; NOTE: This query is a hack until a upstream bug is fixed: neovim/neovim#17060
; where (node)+ quantifiers are not captured properly as a single group.
;   see potential fix: neovim/neovim#17099 -> neovim/neovim#24738
;   also relevant: tree-sitter/tree-sitter#2468
(
  ; The following somehow doesn't work for a very long comments. Might be a bug?
  ; (_) @_non_comment (#not-has-type? @_non_comment comment)
  [
    (function_declaration)
    (assignment_statement)
    (variable_declaration)
    (function_call)
    (do_statement)
    (while_statement)
    (if_statement)
    (for_statement)
  ]
  ; luadoc region with annotations
  . (comment) @_start
  . (comment)*
  . (comment) @_end
  ; function, variable, etc. that is being annotated
  . [
      (function_declaration)
      (assignment_statement)
      (variable_declaration)
      (function_call)
    ]
  (#make-range! "fold" @_start @_end)
)
