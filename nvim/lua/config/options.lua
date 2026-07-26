-- General settings and options for NVIM
-- TODO: migrate many other options config from ~/.vimrc

local augroup = vim.api.nvim_create_augroup('config.options', { clear = true })

-- Allow exrc
vim.o.exrc = true

-- Mouse Options
-- You should also adjust OS-level mouse/trackpad wheel speed
-- (using LinearMouse, Scroll Reverser, macOS builtin Pref "Scroll speed", etc.)
vim.o.mousescroll = 'ver:1,hor:3'

-- Automatically reload files changed externally, when focus is gained
vim.o.autoread = true
vim.api.nvim_create_autocmd('WinEnter', {
  pattern = '*',
  group = augroup,
  callback = function(args)
    local buf = args.buf
    -- skip non-file or special buffers because they don't have an associated file on disk
    if vim.bo[buf].buftype ~= '' then return end
    -- skip if modified, because we don't want to lose unsaved changes
    if vim.bo[buf].modified then return end
    vim.cmd('checktime')
  end,
})
