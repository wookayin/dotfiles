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
  };

  Plug 'nvim-treesitter/playground' {
    name = 'nvim-treesitter-playground',
    commit = '4044b53',
  };

  Plug 'SmiteshP/nvim-gps';
}
