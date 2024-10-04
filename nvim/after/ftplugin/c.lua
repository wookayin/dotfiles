-- ftplugin: c.lua

-- Treesitter highlight
require("config.treesitter").ensure_parsers_installed { "c" }
require("config.treesitter").setup_highlight("c")
