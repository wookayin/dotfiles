-- ftplugin/gitcommit

-- Treesitter highlight
require("config.treesitter").ensure_parsers_installed { "gitcommit", "diff" }
require("config.treesitter").setup_highlight("gitcommit")
vim.bo.syntax = "ON"  -- enable vim syntax, e.g. gitcommitBlank are useful

-- Spell Checking
vim.wo.spell = true

-- Workaround for "invalid bot" errors in vim._foldupdate(), when running :GCommit
vim.wo.foldmethod = 'manual'
