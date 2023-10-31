--[[
  Minimal rc forfile lua unit testing and debugging
  nvim [--headless] --clean -u ~/.dotfiles/nvim/init.testing.lua
]]
print(("Sourcing %s, now = %s"):format(debug.getinfo(1).source, os.date("%Y-%m-%d %H:%M:%S")))

-- Force-reload precompiled built-in modules with source to show better stacktrace,
-- since stacktrace lines like (vim/shared.lua:0) are not quite informative
-- See neovim CMakeLists.txt, search for CHAR_BLOB_GENERATOR
local builtin_mods = { "F", "_editor", "_options", "filetype", "fs", "inspect", "keymap", "loader", "shared" }
for _, mod in ipairs(builtin_mods) do
  package.preload["vim." .. mod] = nil
  package.loaded["vim." .. mod] = nil
  pcall(function()
    vim[mod] = require("vim." .. mod)
  end)
end

-- Always disable swap and shada even if it's not given in the CLI
vim.opt.swapfile = false
vim.opt.shadafile = "NONE"

-- Make plenary.nvim and ./lua always available for lua packages
if not vim.tbl_contains(vim.tbl_map(function(p) return vim.endswith(p, "plenary.nvim") end, vim.opt.runtimepath:get()), true) then
  vim.opt.runtimepath:append(vim.fn.expand("$HOME/.vim/plugged/plenary.nvim"))
end
package.path = 'lua/?.lua;' .. 'lua/?/init.lua;' .. package.path
