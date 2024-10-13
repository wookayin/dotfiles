-- Appearance plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  Plug 'flazz/vim-colorschemes' { lazy = false, priority = 1000 };
  Plug 'rebelot/kanagawa.nvim' { lazy = false, priority = 1000 };

  -- statusline
  Plug 'nvim-lualine/lualine.nvim' {
    event = 'UIEnter',  -- load the plugin earlier than VimEnter, before drawing the UI, to avoid flickering transition
    init = function()
      -- lualine initializes lazily; to hide unwanted text changes in the statusline,
      -- draw an empty statusline with no text before the first draw of lualine
      vim.o.statusline = ' '
    end,
    config = require('config.statusline').setup,
  };

  -- tabline
  Plug 'mg979/vim-xtabline' {
    event = 'UIEnter',  -- load the plugin before drawing UI to not flicker; it takes only 2-3 ms
    init = require("config.tabline").init_xtabline,
    config = require("config.tabline").setup_xtabline,
  };

  -- Additional highlight/extmark providers
  Plug 'lukas-reineke/headlines.nvim' {
    opts = {
      markdown = {
        bullets = {}, -- disable, show '#, '##', '-', etc. as-is
        fat_headlines = false,
        headline_highlights = { "@markup.heading.1.markdown", "@markup.heading.2.markdown" },
        codeblock_highlight = "@markup.raw.block.markdown",
      },
    },
  };

}
