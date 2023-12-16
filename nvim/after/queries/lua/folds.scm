;; extends

; Fold consecutive lines of luadoc comments
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
    ]
  (#make-range! "fold" @_start @_end)
)
