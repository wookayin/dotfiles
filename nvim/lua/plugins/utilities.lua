-- Miscellaneous utility plugins (cmds, etc.)

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  -- Folding
  Plug 'kevinhwang91/nvim-ufo' {
    dependencies = {'kevinhwang91/promise-async'},
  };

  -- Indent Guideline and Scrollbar
  Plug 'lukas-reineke/indent-blankline.nvim' { init = PlugConfig };
  Plug 'dstein64/nvim-scrollview';

  -- Tmux support
  Plug 'christoomey/vim-tmux-navigator' {
    init = PlugConfig
  };
  Plug 'tpope/vim-tbone';

  -- Misc
  Plug 'tpope/vim-commentary' { init = PlugConfig };
  Plug 'szw/vim-maximizer';
  Plug 'tpope/vim-eunuch';
  Plug 'junegunn/vim-emoji';
  Plug 'junegunn/goyo.vim';
  Plug 'junegunn/vader.vim';
  Plug 'cocopon/colorswatch.vim' { cmd = 'ColorSwatchGenerate' };
  Plug 'wookayin/vim-typora' { cmd = 'Typora' };
  Plug 'mrjones2014/dash.nvim' {
    cond = vim.fn.isdirectory('/Applications/Dash.app'),
    build = 'make install',
    cmd = { 'Dash', 'DashWord' },
  };
}
