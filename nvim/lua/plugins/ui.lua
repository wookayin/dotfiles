-- UI-related plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

return {
  -- Basic UI Components
  Plug 'MunifTanjim/nui.nvim' { lazy = true };  -- see config/ui.lua
  Plug 'stevearc/dressing.nvim' { lazy = true };  -- see config/ui.lua
  Plug 'skywind3000/vim-quickui' { event = 'UIEnter' };

  -- FZF & Grep
  Plug 'junegunn/fzf' {
    name = 'fzf',
    dir = '~/.fzf',
    build = './install --all --no-update-rc',
  };
  Plug 'junegunn/fzf.vim' {
    event = 'CmdlineEnter',
  };
  Plug 'wookayin/fzf-ripgrep.vim' {
    cmd = { 'RgFzf', 'Rg', 'RgDefFzf' },
  };

  -- Telescope (config/telescope.lua)
  Plug 'nvim-telescope/telescope.nvim' { lazy = true };

  -- Terminal
  Plug 'voldikss/vim-floaterm' { event = 'CmdlineEnter' };

  -- Wildmenu
  Plug 'gelguy/wilder.nvim' {
    dependencies = {'romgrk/fzy-lua-native'},
    build = UpdateRemotePlugins,
    event = 'CmdlineEnter',
  };

  -- Explorer
  Plug 'nvim-neo-tree/neo-tree.nvim' {
    branch = 'main',
    init = PlugConfig['neo-tree.nvim'],
    event = 'UIEnter',
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
  Plug 'majutsushi/tagbar' { cmd = { 'Tagbar', 'TagbarOpen', 'TagbarToggle' } };

  -- Quickfix
  Plug 'kevinhwang91/nvim-bqf' { ft = 'qf' };

  -- Marks and Signs
  Plug 'kshenoy/vim-signature' {
    event = 'UIEnter',
    config = function()
      -- hlgroups are registered on VimEnter, so need to setup after lazy loading
      pcall(vim.fn['signature#utils#SetupHighlightGroups'])
    end
  };
  Plug 'vim-scripts/errormarker.vim' { event = 'UIEnter' };

  -- Etc
  Plug 'NvChad/nvim-colorizer.lua' { lazy = true };
}
