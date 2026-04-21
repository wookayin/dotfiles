-- use treesitter indentation
-- (NOTE: only compatible with nvim-treesitter v1.0+)
vim.opt_local.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
-- vim.opt_local.indentkeys = '!^F,o,O,<:>,0),0],0},=elif,=except'
