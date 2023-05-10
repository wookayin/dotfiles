-- Treesitter plugins.

local Plug = require('utils.plug_utils').Plug
local function has(f) return vim.fn.has(f) > 0 end

return {
  Plug 'nvim-treesitter/nvim-treesitter' {
    version = (function()
      -- Use the old, stable version that is compatible with the minimum supported neovim verison (0.8.x).
      -- There will be a lot of breaking changes in treesitter; when bumped up, check whether treesitter highlighter works OK.
      -- Note: nvim-treesitter v0.8.0+ is not compatible with neovim 0.8.x
      -- see https://github.com/nvim-treesitter/nvim-treesitter/issues/3092
      return 'v0.7.2'
    end)(),
    build = ':TSUpdateSync',
    lazy = true,  -- see config/treesitter.lua
  };

  Plug 'nvim-treesitter/playground' {
    name = 'nvim-treesitter-playground',
    cmd = 'TSPlaygroundToggle',
    commit = '4044b53',
  };

  Plug 'SmiteshP/nvim-gps' { lazy = true };  -- see config/treesitter.lua
}
