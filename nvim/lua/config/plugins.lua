-- neovim plugins managed by lazy.nvim
-- Plugins specs are located at: ~/.config/nvim/lua/plugins/

local M = {}

local PLUGIN_SPEC = {
  { import = "plugins.basic" },
  { import = "plugins.appearance" },
  { import = "plugins.ui" },
  { import = "plugins.keymap" },
  { import = "plugins.git" },
  { import = "plugins.ide" },
  { import = "plugins.treesitter" },
  { import = "plugins.utilities" },
}

-- $VIMPLUG
-- vim.env.VIMPLUG = vim.fn.stdpath("data") .. "/lazy"
vim.env.VIMPLUG = vim.fn.expand('$HOME/.vim/plugged')

-- Bootstrap lazy.nvim plugin manager
-- https://github.com/folke/lazy.nvim
local lazypath = vim.env.VIMPLUG .. "/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup and load plugins. All plugins will be source HERE!
-- https://github.com/folke/lazy.nvim#%EF%B8%8F-configuration
require("lazy").setup(PLUGIN_SPEC, {
  root = vim.env.VIMPLUG,
  defaults = {
    -- Plugins will be loaded as soon as lazy.setup()
    lazy = false,
  },
  install = {
    missing = true,
    colorscheme = {"xoria256-wook"},
  },
  ui = {
    wrap = true,
    border = 'double',
  },
  performance = {
    rtp = {
      paths = {
        '~/.vim',  -- Allows ~/.vim/colors, etc. accessible
      }
    },
  },
  change_detection = {
    notify = true,
  },
})

-- Close auto-install window
vim.cmd [[
  if &filetype == 'lazy' | q | endif
]]

-- Add rplugins support on startup; see utils/plug_utils.lua
require("utils.plug_utils").UpdateRemotePlugins()

-- Disable lazy clean by monkey-patching. (see #762)
require("lazy.manage").clean = function(opts)
  print("[lazy.nvim] Clean operation is disabled.")
  return require("lazy.manage").run({ pipeline = {} })
end

-- remap keymaps and configure lazy window
require("lazy.view.config").keys.profile_filter = "<C-g>"
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lazy",
  callback = function()
    vim.defer_fn(function()
      -- Ctrl+C: to quit the window
      vim.keymap.set("n", "<C-c>", "q", { buffer = true, remap = true })

      -- Highlights
      vim.cmd [[
        hi! LazyProp guibg=NONE
      ]]
    end, 0)
  end,
})

-- load: immediately load (lazy) plugins synchronously
function M.load(names)
  require("lazy.core.loader").load(names, {}, { force = true })
end

return M
