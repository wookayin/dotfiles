;; extends

; highlight \iffalse .. \fi comments differently
((block_comment) @comment.special)

; highlight $ delimiters in inline math
(inline_formula
  "$" @markup.math.delimiter)

;; Formatting (extended)

((generic_command
  command: (command_name) @_name
  arg: (curly_group (_) @markup.underline))
 (#any-of? @_name "\\underline" "\\uline"))
