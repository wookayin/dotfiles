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

; exec_lua [[ ... ]]
; => see functional tests in neovim
((function_call
  name: (_) @_exec_lua
  arguments: (arguments (string content: _ @injection.content)))
  (#eq? @_exec_lua "exec_lua")
  (#set! injection.language "lua")
  )
