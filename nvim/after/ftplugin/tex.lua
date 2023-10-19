-- ftplugin: tex.lua
-- See also ftplugin/tex.vim which needs migration to lua

-- Use treesitter highlight for latex (experimental)
require('config.treesitter').ensure_parsers_installed { 'latex' }
require('config.treesitter').setup_highlight('latex')

-- Configure :Build
require('config.tex').setup_compiler_commands()

local path = require("utils.path_utils")
vim.b.project_root = path.find_project_root({ 'Makefile', '.latexmkrc', '.git' }, { buf = 0 })

-- FZF-based quickjump
-- Quickly lookup all \section{...} and \subsection{...} definitions.
-- A limitation: can't recognize commands inside comments or verbatim, etc.
vim.api.nvim_buf_create_user_command(0, 'Sections', function(e)
  local pattern = '^\\\\((sub)?section|chapter|paragraph)\\*?\\{'

  local rg_defaults = require('fzf-lua.defaults').defaults.grep.rg_opts
  require("fzf-lua").grep {
    no_esc = true, -- we are using raw regex
    search = pattern,
    query = vim.trim(e.args or ''),
    headers = {},  -- the ctrl-g to "Regex Search" .. is misleading,
    prompt = 'TeX sections❯ ',
    rg_opts = [[ --type "tex" ]] .. rg_defaults,
    fzf_opts = { ['--delimiter'] = ':', ['--nth'] = '3..' },  -- filter by text
    previewer = 'builtin',
    winopts = { preview = { layout = "vertical", vertical = "down:33%" } },
    cwd = vim.b.project_root,  -- not the cwd
  }
end, {
  nargs = '?',
  desc = 'Sections -- look up \\section{...} and \\subsection{...} definitions',
})

-- :V -- table of contents
vim.keymap.set('n', '<leader>V', function()
  vim.fn['vimtex#fzf#run']("ctli", {
    window = "call FloatingFZF()",
  })
end, { buffer = true, desc = 'TeX: Table of Contents with fzf' })
