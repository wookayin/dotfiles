;; extends

; (recipe_body) is highlighted with @string (in color) even if it has injections.
; To prevent this, highlight injected regions with white foreground.
(recipe
  (recipe_body) @command
  (#set! priority 99))
