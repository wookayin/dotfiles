-- ftplugin: tex.lua
-- See also ftplugin/tex.vim which needs migration to lua

-- Use treesitter highlight for latex (experimental)
require('config.treesitter').ensure_parsers_installed { 'latex' }
require('config.treesitter').setup_highlight('latex')

-- Configure :Build
require('config.tex').setup_compiler_commands()
