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
        tabline_modes = { 'tabs', 'buffers', 'arglist' },
        -- always show the current xtabline mode
        mode_labels = 'all',
      }
    end,
    config = function()
      require("utils.rc_utils").RegisterHighlights(function()
        vim.api.nvim_set_hl(0, 'XTNum',    { bg = 'black',   fg='white', })
        vim.api.nvim_set_hl(0, 'XTNumSel', { bg = '#1f1f3d', fg='white', bold = true })
        vim.api.nvim_set_hl(0, 'XTCorner', { link = 'Special' })
      end)
    end,
  };
}
