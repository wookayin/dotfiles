-- Git-related plugins.

local Plug = require('utils.plug_utils').Plug

return {
  Plug 'tpope/vim-fugitive';
  Plug 'junegunn/gv.vim';

  Plug 'lewis6991/gitsigns.nvim' {
    -- See GH-768
    commit = vim.fn.has('nvim-0.8.0') == 0 and '76b71f74' or nil,
  };

  Plug 'sindrets/diffview.nvim';
  Plug 'rhysd/git-messenger.vim';
}
