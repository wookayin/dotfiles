-- Appearance plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  Plug 'flazz/vim-colorschemes' { lazy = false, priority = 1000 };

  -- statusline
  Plug 'nvim-lualine/lualine.nvim' {
    event = 'UIEnter',
    config = require('config.statusline').setup,
  };

  -- tabline
  Plug 'mg979/vim-xtabline' {
    -- can be initialized lazily after vim UI is ready
    event = 'UIEnter',
    init = PlugConfig,
  };
}
