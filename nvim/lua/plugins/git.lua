-- Git-related plugins.

local Plug = require('utils.plug_utils').Plug

return {
  Plug 'tpope/vim-fugitive' {
    ft = 'fugitiveblame',
    event = {'CmdlineEnter'},   -- so many :G.. commands
  };
  Plug 'junegunn/gv.vim' {
    cmd = 'GV',
    dependencies = 'tpope/vim-fugitive',
  };

  Plug 'lewis6991/gitsigns.nvim' {
    -- See GH-768
    commit = vim.fn.has('nvim-0.8.0') == 0 and '76b71f74' or nil,
    event = 'UIEnter',
  };

  Plug 'sindrets/diffview.nvim' { lazy = true };  -- config/git.lua
  Plug 'rhysd/git-messenger.vim' { keys = '<leader>gm' };
}
