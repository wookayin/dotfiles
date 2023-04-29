-- Keymap related plugins (cmds, etc.)

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  -- Keymaps
  Plug 'junegunn/vim-peekaboo';
  Plug 'folke/which-key.nvim' { init = PlugConfig };

  -- Actions and operators
  Plug 'Lokaltog/vim-easymotion';
  Plug 'junegunn/vim-easy-align';
  Plug 'tpope/vim-surround';
  Plug 'tpope/vim-repeat';
  Plug 'haya14busa/vim-asterisk' { init = PlugConfig };
  Plug 'haya14busa/incsearch.vim' { init = PlugConfig };
  Plug 'haya14busa/incsearch-fuzzy.vim';
  Plug 'unblevable/quick-scope' {
    keys = { 'f', 'F', 't', 'T'}
  };
  Plug 't9md/vim-quickhl';
  Plug 'vim-scripts/matchit.zip';  -- Extended %

  -- Undo
  Plug 'sjl/gundo.vim';
  Plug 'machakann/vim-highlightedundo' {
    cond = vim.fn.executable('diff') > 0,
    init = PlugConfig,
  };
}
