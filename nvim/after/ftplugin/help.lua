--- Enable treesitter highlight on vim help [vimdoc]
if vim.fn.has('nvim-0.9.0') > 0 then
  vim.treesitter.start()
end

--- [[ Keymap ]]
-- Make navigation and jump within help doc more easier
local nbufmap = function(lhs, rhs) vim.keymap.set('n', lhs, rhs, { buffer = true, nowait = true }) end
nbufmap('gd', '<C-]>')
nbufmap('<CR>', '<C-]>')
nbufmap('<C-[>', '<C-o>')
