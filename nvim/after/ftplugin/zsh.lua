-- ftplugin/zsh.lua

-- Treesitter highlight: NOT YET, until a parser is available
-- https://github.com/nvim-treesitter/nvim-treesitter/issues/655
-- require("config.treesitter").setup_highlight("bash")

-- Tab size
vim.opt_local.ts = 2
vim.opt_local.sts = 2
vim.opt_local.sw = 2

-- Make support for easily running unit tests
if vim.endswith(vim.fn.bufname() or "", "_test.zsh") then
  vim.opt_local.makeprg = 'zunit --verbose %'
end
