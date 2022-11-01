-- Fixes function key mappings for neovim on xterm-* TERMs.

-- @author Jongwook Choi <wookayin@gmail.com>
-- This file is licensed at the PUBLIC DOMAIN (PD) LICENSE

-- Unlike vanilla vim, neovim recognizes modifier keys + function keys differently
-- as per the terminfo listings. For example, xterm-256color defines <F13> for Shift-F1.
-- Thus we remap all the special keycodes (e.g., <F13> .. <F60>), so we can use
-- normal modifier-enabled keycodes (e.g. <S-F1> .. <M-12>) everywhere in the config.


local condition = vim.fn.has('nvim-0.7.0') > 0 and vim.fn.expand('$TERM'):match("^xterm")
if not condition then return end

local mode = { 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't' }
local opts = { silent = true, nowait = true, noremap = false, remap = true }

-- Shift + F1-F12
vim.keymap.set(mode, '<F13>', '<S-F1>', opts)
vim.keymap.set(mode, '<F14>', '<S-F2>', opts)
vim.keymap.set(mode, '<F15>', '<S-F3>', opts)
vim.keymap.set(mode, '<F16>', '<S-F4>', opts)
vim.keymap.set(mode, '<F17>', '<S-F5>', opts)
vim.keymap.set(mode, '<F18>', '<S-F6>', opts)
vim.keymap.set(mode, '<F19>', '<S-F7>', opts)
vim.keymap.set(mode, '<F20>', '<S-F8>', opts)
vim.keymap.set(mode, '<F21>', '<S-F9>', opts)
vim.keymap.set(mode, '<F22>', '<S-F10>', opts)
vim.keymap.set(mode, '<F23>', '<S-F11>', opts)
vim.keymap.set(mode, '<F24>', '<S-F12>', opts)

-- Ctrl + F1-F12
vim.keymap.set(mode, '<F25>', '<C-F1>', opts)
vim.keymap.set(mode, '<F26>', '<C-F2>', opts)
vim.keymap.set(mode, '<F27>', '<C-F3>', opts)
vim.keymap.set(mode, '<F28>', '<C-F4>', opts)
vim.keymap.set(mode, '<F29>', '<C-F5>', opts)
vim.keymap.set(mode, '<F30>', '<C-F6>', opts)
vim.keymap.set(mode, '<F31>', '<C-F7>', opts)
vim.keymap.set(mode, '<F32>', '<C-F8>', opts)
vim.keymap.set(mode, '<F33>', '<C-F9>', opts)
vim.keymap.set(mode, '<F34>', '<C-F10>', opts)
vim.keymap.set(mode, '<F35>', '<C-F11>', opts)
vim.keymap.set(mode, '<F36>', '<C-F12>', opts)

-- Ctrl + Shift + F1-F12
vim.keymap.set(mode, '<F37>', '<C-S-F1>', opts)
vim.keymap.set(mode, '<F38>', '<C-S-F2>', opts)
vim.keymap.set(mode, '<F39>', '<C-S-F3>', opts)
vim.keymap.set(mode, '<F40>', '<C-S-F4>', opts)
vim.keymap.set(mode, '<F41>', '<C-S-F5>', opts)
vim.keymap.set(mode, '<F42>', '<C-S-F6>', opts)
vim.keymap.set(mode, '<F43>', '<C-S-F7>', opts)
vim.keymap.set(mode, '<F44>', '<C-S-F8>', opts)
vim.keymap.set(mode, '<F45>', '<C-S-F9>', opts)
vim.keymap.set(mode, '<F46>', '<C-S-F10>', opts)
vim.keymap.set(mode, '<F47>', '<C-S-F11>', opts)
vim.keymap.set(mode, '<F48>', '<C-S-F12>', opts)

-- Alt + F1-F12
vim.keymap.set(mode, '<F49>', '<M-F1>', opts)
vim.keymap.set(mode, '<F50>', '<M-F2>', opts)
vim.keymap.set(mode, '<F51>', '<M-F3>', opts)
vim.keymap.set(mode, '<F52>', '<M-F4>', opts)
vim.keymap.set(mode, '<F53>', '<M-F5>', opts)
vim.keymap.set(mode, '<F54>', '<M-F6>', opts)
vim.keymap.set(mode, '<F55>', '<M-F7>', opts)
vim.keymap.set(mode, '<F56>', '<M-F8>', opts)
vim.keymap.set(mode, '<F57>', '<M-F9>', opts)
vim.keymap.set(mode, '<F58>', '<M-F10>', opts)
vim.keymap.set(mode, '<F59>', '<M-F11>', opts)
vim.keymap.set(mode, '<F60>', '<M-F12>', opts)

-- Other possible combinations among Alt, Shift, Ctrl
-- Alt + Shift        : correctly recognized as <M-S-F%d>
-- Alt + Ctrl         : correctly recognized as <M-C-F%d>
-- Alt + Ctrl + Shift : correctly recognized as <M-C-S-F%d>
