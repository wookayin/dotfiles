-- Miscellaneous utility plugins (cmds, etc.)

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  -- Folding
  Plug 'kevinhwang91/nvim-ufo' {
    dependencies = {'kevinhwang91/promise-async'},
    event = 'UIEnter',
    config = require('config.folding').setup,
  };

  -- Indent Guideline and Scrollbar
  Plug 'lukas-reineke/indent-blankline.nvim' { init = PlugConfig, event = 'UIEnter' };
  Plug 'dstein64/nvim-scrollview' { event = 'UIEnter' };

  -- Tmux support
  Plug 'christoomey/vim-tmux-navigator' { init = PlugConfig, event = 'UIEnter' };
  Plug 'tpope/vim-tbone' { cmd = 'Tmux' };

  -- Misc
  Plug 'tpope/vim-commentary' { init = PlugConfig, event = 'UIEnter' };
  Plug 'szw/vim-maximizer' { cmd = 'MaximizerToggle' };
  Plug 'tpope/vim-eunuch' { event = 'CmdlineEnter' };
  Plug 'junegunn/vim-emoji' { lazy = true, func = 'emoji#*' };
  Plug 'junegunn/goyo.vim' { cmd = 'Goyo' };
  Plug 'junegunn/vader.vim' { cmd = 'Vader', ft = 'vader' };
  Plug 'cocopon/colorswatch.vim' { cmd = 'ColorSwatchGenerate' };
  Plug 'wookayin/vim-typora' { cmd = 'Typora' };
  Plug 'mrjones2014/dash.nvim' {
    enabled = vim.fn.isdirectory('/Applications/Dash.app') > 0,
    build = 'make install',
    cmd = { 'Dash', 'DashWord' },
  };
}
