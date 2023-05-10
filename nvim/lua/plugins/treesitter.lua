-- Treesitter plugins.

local Plug = require('utils.plug_utils').Plug
local function has(f) return vim.fn.has(f) > 0 end

return {
  Plug 'nvim-treesitter/nvim-treesitter' {
    build = ':TSUpdateSync',
    version = (function()
      if not has('nvim-0.8') then return 'v0.7.2' end
      return '*'  -- use stable release
    end)(),
    lazy = true,  -- see config/treesitter.lua
  };

  Plug 'nvim-treesitter/playground' {
    name = 'nvim-treesitter-playground',
    cmd = 'TSPlaygroundToggle',
    commit = '4044b53',
  };

  Plug 'SmiteshP/nvim-gps' { lazy = true };  -- see config/treesitter.lua
}
