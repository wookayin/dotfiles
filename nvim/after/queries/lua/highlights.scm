;; extends
; see also $DOTVIM/after/queries/lua/injections.scm

; Fix @vim injections having wrong (string) foregrounds
; thanks to u/Adk9p (https://www.reddit.com/r/neovim/comments/1059xht/)
; see $DOTVIM/after/queries/lua/injections.scm
((function_call
  name: (_) @_vimcmd_identifier
  arguments: (arguments (string content: _ @string.injection @nospell)))
  (#any-of? @_vimcmd_identifier
    "vim.cmd" "vim.api.nvim_command" "vim.api.nvim_exec" "vim.api.nvim_exec2"
    "vim_cmd"  ; custom local function
    )
  )

; functional tests in neovim
; exec_lua [[ ... ]]
((function_call
  name: (_) @_exec_lua (#eq? @_exec_lua "exec_lua")
  arguments: (arguments (string content: _ @string.injection)))
)
; pcall(exec_lua, ...) pcall_err(exec_lua, ...)
((function_call
  name: (_) @_pcall (#any-of? @_pcall "pcall" "pcall_err")
  arguments: (arguments
               . (identifier) @_exec_lua (#eq? @_exec_lua "exec_lua")
               . (string content: _ @string.injection)))
)

; literal query in lua files: local query = [[ ... ]]
((assignment_statement
    (variable_list
      name: (identifier) @_identifier)
    (#eq? @_identifier "query")
    (expression_list
      value: (string content: (string_content) @string.injection @markup.italic))
  )
)
; CSS injection: local css = [[ .... ]]
((assignment_statement
    (variable_list
      name: (identifier) @_identifier)
    (#eq? @_identifier "css")
    (expression_list
      value: (string content: (string_content) @string.injection))
  )
)
