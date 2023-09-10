;; extends

; Fix @vim injections having wrong (string) foregrounds
; thanks to u/Adk9p (https://www.reddit.com/r/neovim/comments/1059xht/)
; see $VIMPLUG/nvim-treesitter/queries/lua/injections.scm
((function_call
  name: (_) @_vimcmd_identifier
  arguments: (arguments (string content: _ @none @nospell)))
  (#any-of? @_vimcmd_identifier "vim.cmd" "vim.api.nvim_command" "vim.api.nvim_exec"))
