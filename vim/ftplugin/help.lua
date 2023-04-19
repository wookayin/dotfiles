-- Enable treesitter highlight on vim help [vimdoc]
if vim.fn.has('nvim-0.9.0') > 0 then
  vim.treesitter.start()
end
