-- ftplugin for bibtex files
-- Loads and works only on neovim 0.7.0 or higher


-- Configure :Build
require('config.tex').setup_compiler_commands()

-- Ensure bibtex TS parsers are installed when opening .bib files for the first time
require('config.treesitter').ensure_parsers_installed { 'bibtex' }

-- Build path
local path = require("utils.path_utils")
vim.b.project_root = path.find_project_root({ 'Makefile', '.latexmkrc', '.git' }, { buf = 0 })
if vim.b.project_root then vim.cmd.lcd(vim.b.project_root) end
