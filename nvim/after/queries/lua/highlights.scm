;; extends

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

; exec_lua [[ ... ]] => see functional tests in neovim
((function_call
  name: (_) @_exec_lua
  arguments: (arguments (string content: _ @string.injection)))
  (#eq? @_exec_lua "exec_lua")
  )
