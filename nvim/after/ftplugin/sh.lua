-- ftplugin/sh.lua (bash)

-- Treesitter highlight
require("config.treesitter").setup_highlight("bash")

-- Tab size
vim.opt_local.ts = 2
vim.opt_local.sts = 2
vim.opt_local.sw = 2
