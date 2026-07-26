--- typescript.lua ftplugin

-- ts/tsx: treesitter highlight support
require("config.treesitter").ensure_parsers_installed { "javascript", "typescript" }
require("config.treesitter").setup_highlight("typescript")
