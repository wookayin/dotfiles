;; extends

; 🚧 Fold a maximially consecutive top-level import statements.
; NOTE: This query is a hack until a upstream bug is fixed: neovim/neovim#17060
; where (node)+ quantifiers are not captured properly as a single group.
;   see potential fix: neovim/neovim#17099 -> neovim/neovim#24738
;   also relevant: tree-sitter/tree-sitter#2468
(module
  . (comment)*
  . (expression_statement)?   ; an optional docstring at the very first top
  . (comment)*
  ; Capture a region of consecutive import statements to fold
  . [(import_statement) (import_from_statement) (future_import_statement)] @_start
  . [(import_statement) (import_from_statement) (future_import_statement) (comment)]*
  . [(import_statement) (import_from_statement) (future_import_statement)]+ @_end
  ; ... until the first non-import node.
  . (_)  @_non_import1  (#not-has-type? @_non_import1  import_statement import_from_statement future_import_statement)
  ; However, don't match if followed by another import statement,
  ; to ensure the capture group is maximial and avoid nested foldings.
  . (_)? @_non_import2  (#not-has-type? @_non_import2  import_statement import_from_statement future_import_statement)

  (#make-range! "fold" @_start @_end)
)
