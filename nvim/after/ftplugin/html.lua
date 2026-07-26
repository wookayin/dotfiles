--- html.lua ftplugin

-- Treesitter highlight
require('config.treesitter').ensure_parsers_installed { 'html', 'html_tags', 'javascript', 'css' }
require('config.treesitter').setup_highlight('html')
