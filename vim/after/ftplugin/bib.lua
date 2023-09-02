-- ftplugin for bibtex files
-- Loads and works only on neovim 0.7.0 or higher


-- Configure :Build
require('config.tex').setup_compiler_commands()

-- Ensure bibtex TS parsers are installed when opening .bib files for the first time
if pcall(require, 'nvim-treesitter.parsers') then
  local parsers = require 'nvim-treesitter.parsers'
  if not parsers.get_parser(0, 'bibtex') then
    require("nvim-treesitter.install").ensure_installed({ 'bibtex' })
  end
end
