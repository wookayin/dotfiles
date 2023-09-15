-- ftplugin: tex.lua
-- See also ftplugin/tex.vim which needs migration to lua

-- Use treesitter highlight for latex (experimental)
require('config.treesitter').ensure_parsers_installed { 'latex' }
require('config.treesitter').setup_highlight('latex')

-- Configure :Build
require('config.tex').setup_compiler_commands()


local project_root = vim.fn.fnamemodify(vim.fs.find(
  { 'Makefile', '.latexmkrc', '.git' }, {
    upward = true, stop = vim.loop.os_homedir(), limit = 1,
    path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  })[1], ":p:h")

-- FZF-based quickjump
-- Quickly lookup all \section{...} and \subsection{...} definitions.
-- A limitation: can't recognize commands inside comments or verbatim, etc.
vim.api.nvim_buf_create_user_command(0, 'Sections', function(opts)
  local cmd = "rg -i --column --line-number --no-heading --color=always "
  cmd = cmd .. vim.fn.shellescape('^\\\\(sub)?section\\{')
  require("fzf-lua").fzf_exec(cmd, {
    prompt = 'TeX sections❯ ',
    previewer = 'builtin',
    actions = require("fzf-lua.defaults").globals.actions.files,
    cwd = project_root,
  })
end, {
  nargs = '?',
  desc = 'Sections -- look up \\section{...} and \\subsection{...} definitions',
})
