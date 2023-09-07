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
    init = function()
      vim.g.xtabline_settings = {
        -- Use 'tab' as the default xtabline mode
        -- since we use global statusline (laststatus = 3)
        tabline_modes = { 'tabs', 'buffers', 'arglist' }
      }
    end,
  };
}
