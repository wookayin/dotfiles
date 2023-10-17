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

--- [[ helpful.vim ]]
-- Automatically show :HelpfulVersion information as the cursor is moved
-- and as soon as we enter the buffer for the first time
-- (Note: do not use b:helpful = 1 because we want to control autocmd on our own)
vim.cmd [[
  augroup helpful_auto
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call helpful#cursor_word()
  augroup END
]]
