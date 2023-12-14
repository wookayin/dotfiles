;; extends

; highlight \iffalse .. \fi comments differently
((block_comment) @comment.special)


;; Formatting (extended)

((generic_command
  command: (command_name) @_name
  arg: (curly_group (_) @text.underline))
 (#any-of? @_name "\\underline" "\\uline"))
