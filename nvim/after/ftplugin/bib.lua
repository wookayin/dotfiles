-- ftplugin for bibtex files
-- Loads and works only on neovim 0.7.0 or higher


-- Configure :Build
require('config.tex').setup_compiler_commands()

-- Ensure bibtex TS parsers are installed when opening .bib files for the first time
require('config.treesitter').ensure_parsers_installed { 'bibtex' }

-- Build path
local path_utils = require("utils.path_utils")
vim.b.project_root = path_utils.project_root(0, { 'Makefile', '.latexmkrc', '.git' })
if vim.b.project_root then vim.cmd.lcd(vim.b.project_root) end
