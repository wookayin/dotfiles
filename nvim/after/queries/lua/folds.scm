;; extends

; Fold [[ ... ]] strings
(string
  "[[" (string_content) "]]"
) @fold


; Fold a maximally consecutive lines of luadoc comments.
(
  (comment)+ @fold
  .
  [
    (function_declaration)
    (assignment_statement)
    (variable_declaration)
    (function_call)
  ]
)
