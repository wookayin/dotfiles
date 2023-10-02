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
  })[1], ":h")  -- don't use :p, it addes trailing slashes when matched .git

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
    cwd = project_root,  -- not the cwd
  }
end, {
  nargs = '?',
  desc = 'Sections -- look up \\section{...} and \\subsection{...} definitions',
})
