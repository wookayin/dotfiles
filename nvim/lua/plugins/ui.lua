-- UI-related plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

return {
  -- Basic UI Components
  Plug 'MunifTanjim/nui.nvim' { lazy = true };  -- see config/ui.lua
  Plug 'stevearc/dressing.nvim' { event = 'UIEnter', config = require 'config.ui'.setup_dressing };
  Plug 'skywind3000/vim-quickui' { event = 'UIEnter' };

  -- FZF & Grep
  Plug 'junegunn/fzf' {
    name = 'fzf',
    dir = '~/.fzf',
    build = './install --all --no-update-rc',
    cmd = 'FZF', func = 'fzf#*',
  };
  Plug 'junegunn/fzf.vim' {
    event = 'CmdlineEnter',
    func = 'fzf#vim#*', lazy = true,
  };
  Plug 'wookayin/fzf-ripgrep.vim' {
    cmd = { 'RgFzf', 'Rg', 'RgDefFzf' },
    func = 'fzf#vim#ripgrep#*', lazy = true,
  };
  Plug 'rking/ag.vim' { func = 'ag#*', lazy = true };

  -- Telescope (config/telescope.lua)
  Plug 'nvim-telescope/telescope.nvim' { lazy = true };

  -- Terminal
  Plug 'voldikss/vim-floaterm' { event = 'CmdlineEnter' };

  -- Wildmenu
  Plug 'wookayin/wilder.nvim' {
    dependencies = {'romgrk/fzy-lua-native'},
    build = UpdateRemotePlugins,
    event = 'CmdlineEnter',
    func = 'wilder#*',
  };

  -- Explorer
  Plug 'nvim-neo-tree/neo-tree.nvim' {
    branch = 'main',
    event = (function()
      -- If any of the startup argument is a directory,
      -- we don't lazy-load neotree so it can hijack netrw.
      if vim.tbl_contains(vim.tbl_map(vim.fn.isdirectory, vim.fn.argv()), 1) then return nil
      else return 'UIEnter' end
    end)(),
    init = function() vim.g.neo_tree_remove_legacy_commands = 1; end,
    config = require 'config.neotree'.setup_neotree,
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
