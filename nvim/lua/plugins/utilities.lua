-- Miscellaneous utility plugins (cmds, etc.)
---@diagnostic disable: missing-fields

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  -- Folding
  Plug 'kevinhwang91/nvim-ufo' {
    dependencies = {'kevinhwang91/promise-async'},
    event = 'VeryLazy',
    config = require('config.folding').setup,
  };

  -- Better Undo
  Plug 'kevinhwang91/nvim-fundo' {
    dependencies = {'kevinhwang91/promise-async'},
    init = function() vim.o.undofile = true; end,
    opts = {},
  };

  -- Indent Guideline and Scrollbar
  Plug 'lukas-reineke/indent-blankline.nvim' { tag = 'v2.20.8', init = PlugConfig, event = 'VeryLazy' };
  Plug 'dstein64/nvim-scrollview' { event = 'VeryLazy' };

  -- Tmux support
  Plug 'christoomey/vim-tmux-navigator' { init = PlugConfig, event = 'VeryLazy' };
  Plug 'tpope/vim-tbone' { cmd = 'Tmux' };

  -- Clipboard
  Plug 'ojroques/nvim-osc52' {
    config = require("config.utilities").setup_osc52,
    enabled = #(os.getenv('SSH_TTY') or "") > 0,  -- if inside SSH
  };

  -- Misc
  Plug 'lewis6991/hover.nvim' {
    config = require("config.utilities").setup_hover,
    keys = { { "K", "<cmd>lua require('hover').hover()<CR>" } },
  };
  Plug 'tpope/vim-commentary' { init = PlugConfig, event = 'VeryLazy' };
  Plug 'szw/vim-maximizer' { cmd = 'MaximizerToggle' };
  Plug 'tpope/vim-eunuch' { event = 'CmdlineEnter', init = function() vim.g.eunuch_no_maps = true; end };
  Plug 'junegunn/goyo.vim' { cmd = 'Goyo' };
  Plug 'junegunn/vader.vim' { cmd = 'Vader', ft = 'vader' };
  Plug 'cocopon/colorswatch.vim' { cmd = 'ColorSwatchGenerate' };
  Plug 'wookayin/vim-typora' { cmd = 'Typora' };
  Plug 'mrjones2014/dash.nvim' {
    enabled = vim.fn.isdirectory('/Applications/Dash.app') > 0,
    build = 'make install',
    cmd = { 'Dash', 'DashWord' },
  };
  Plug 'darfink/vim-plist' { enabled = vim.fn.has('mac') > 0 };
}
