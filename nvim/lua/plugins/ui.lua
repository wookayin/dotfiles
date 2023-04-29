-- UI-related plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

return {
  -- Basic UI Components
  Plug 'MunifTanjim/nui.nvim';
  Plug 'stevearc/dressing.nvim';
  Plug 'skywind3000/vim-quickui';

  -- FZF & Grep
  Plug 'junegunn/fzf' {
    name = 'fzf',
    dir = '~/.fzf',
    build = './install --all --no-update-rc',
  };
  Plug 'junegunn/fzf.vim';
  Plug 'wookayin/fzf-ripgrep.vim';

  -- Telescope
  Plug 'nvim-telescope/telescope.nvim';

  -- Terminal
  Plug 'voldikss/vim-floaterm';

  -- Wildmenu
  Plug 'gelguy/wilder.nvim' {
    dependencies = {'romgrk/fzy-lua-native'},
    build = UpdateRemotePlugins,
  };

  -- Explorer
  Plug 'nvim-neo-tree/neo-tree.nvim' {
    branch = 'main',
    init = PlugConfig['neo-tree.nvim'],
  };

  Plug 'scrooloose/nerdtree' {
    cmd = { 'NERDTree', 'NERDTreeToggle', 'NERDTreeTabsToggle' },
    keys = '<Plug>NERDTreeTabsToggle',
    dependencies = {
      Plug 'jistr/vim-nerdtree-tabs';
      Plug 'Xuyuanp/nerdtree-git-plugin';
    },
  };

  -- Navigation
  Plug 'vim-voom/VOoM' { cmd = { 'Voom', 'VoomToggle' } };
  Plug 'majutsushi/tagbar';

  -- Quickfix
  Plug 'kevinhwang91/nvim-bqf';

  -- Marks and Signs
  Plug 'kshenoy/vim-signature';
  Plug 'vim-scripts/errormarker.vim';

  -- Etc
  Plug 'NvChad/nvim-colorizer.lua';
}
