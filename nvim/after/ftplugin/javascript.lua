--- javascript.lua ftplugin

-- Treesitter highlight
require("config.treesitter").ensure_parsers_installed { "javascript" }
require("config.treesitter").setup_highlight("javascript")

-- Use tab size 2
local setlocal = vim.opt_local
setlocal.expandtab = true
setlocal.ts = 2
setlocal.sw = 2
setlocal.sts = 2

-- tree-sitter grammar support (grammar.js)
local filename = vim.fn.expand("%:p:t")
local dir_last = vim.fn.expand("%:p:h:t") --[[ @as string ]]
if filename == "grammar.js" and vim.startswith(dir_last, "tree-sitter") then
  setlocal.makeprg = 'npm run build && npm run test'
end
