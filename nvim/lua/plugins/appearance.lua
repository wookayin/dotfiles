-- Appearance plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  Plug 'flazz/vim-colorschemes' { lazy = false, priority = 1000 };
  Plug 'rebelot/kanagawa.nvim' { lazy = false, priority = 1000 };

  -- statusline
  Plug 'nvim-lualine/lualine.nvim' {
    event = 'UIEnter',  -- load the plugin earlier than VimEnter, before drawing the UI, to avoid flickering transition
    config = require('config.statusline').setup,
  };

  -- tabline
  Plug 'mg979/vim-xtabline' {
    event = 'UIEnter',  -- load the plugin before drawing UI to not flicker; it takes only 2-3 ms
    init = require("config.tabline").init_xtabline,
    config = require("config.tabline").setup_xtabline,
  };
}
