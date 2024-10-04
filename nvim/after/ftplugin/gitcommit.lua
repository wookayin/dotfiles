-- ftplugin/gitcommit

-- Treesitter highlight
require("config.treesitter").ensure_parsers_installed { "gitcommit", "diff" }
require("config.treesitter").setup_highlight("gitcommit")
vim.bo.syntax = "ON"  -- enable vim syntax, e.g. gitcommitBlank are useful
