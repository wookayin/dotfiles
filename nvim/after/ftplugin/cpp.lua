-- ftplugin: cpp.lua

-- Treesitter highlight
require("config.treesitter").ensure_parsers_installed { "cpp" }
require("config.treesitter").setup_highlight("cpp")
