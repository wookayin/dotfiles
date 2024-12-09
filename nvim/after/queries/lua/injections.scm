;; extends
; see $DOTVIM/after/queries/lua/highlights.scm
; see also -- :TSEditQuery injections lua


; vim.cmd [[ ... ]]
((function_call
  name: (_) @_vimcmd_identifier
  arguments: (arguments (string content: _ @injection.content)))
  (#any-of? @_vimcmd_identifier
    "vim.cmd" "vim.api.nvim_command" "vim.api.nvim_exec" "vim.api.nvim_exec2"
    "vim_cmd"  ; custom local function
    )
  (#set! injection.language "vim")
  )

; functional tests in neovim
; exec_lua [[ ... ]]
((function_call
  name: (_) @_exec_lua (#eq? @_exec_lua "exec_lua")
  arguments: (arguments (string content: _ @injection.content)))
 (#set! injection.language "lua")
)
; pcall(exec_lua, ...) pcall_err(exec_lua, ...)
((function_call
  name: (_) @_pcall (#any-of? @_pcall "pcall" "pcall_err")
  arguments: (arguments
               . (identifier) @_exec_lua (#eq? @_exec_lua "exec_lua")
               . (string content: _ @injection.content)))
 (#set! injection.language "lua")
)

; query injection: local query = [[ ... ]]
((assignment_statement
    (variable_list
      name: (identifier) @_identifier)
    (#eq? @_identifier "query")
    (expression_list
      value: (string content: (string_content) @injection.content))
  )
  (#set! injection.language "query")
)
; CSS injection: local css = [[ .... ]]
((assignment_statement
    (variable_list
      name: (identifier) @_identifier)
    (#eq? @_identifier "css")
    (expression_list
      value: (string content: (string_content) @injection.content))
  )
  (#set! injection.language "css")
)
