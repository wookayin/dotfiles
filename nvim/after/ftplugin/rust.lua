-- ftplugin: rust.lua

-- Use treesitter highlight
require("config.treesitter").ensure_parsers_installed { "rust" }
require("config.treesitter").setup_highlight("rust")
