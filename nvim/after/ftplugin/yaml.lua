-- treesitter highlight
require("config.treesitter").ensure_parsers_installed { "yaml" }
require("config.treesitter").setup_highlight("yaml")

-- yaml: use tabsize of 2
local setlocal = vim.opt_local
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2
setlocal.expandtab = true
