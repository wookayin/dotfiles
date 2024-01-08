-- UI-related plugins.

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

local has_py3 = function(p) return require('config.pynvim')() end

return {
  -- Basic UI Components
  Plug 'MunifTanjim/nui.nvim' { lazy = true };  -- see config/ui.lua
  Plug 'stevearc/dressing.nvim' { event = 'VeryLazy', config = require 'config.ui'.setup_dressing };
  Plug 'skywind3000/vim-quickui' {
    event = 'VeryLazy',
    init = require('config.ui').init_quickui,
    config = require('config.ui').setup_quickui,
  };

  -- FZF & Grep
  Plug 'junegunn/fzf' {
    name = 'fzf',
    dir = '~/.fzf',
    enabled = (function()
      if vim.fn.isdirectory(vim.fn.expand("$HOME/.fzf")) == 0 then
        local msg = "~/.fzf not found. Please run `dotfiles update`"
        vim.defer_fn(function()
          vim.notify(msg, vim.log.levels.WARN, { title = "plugins.ui", markdown = true })
        end, 100) -- nvim-notify might be not ready yet
        return false
      end
      return true
    end)(),
    build = './install --all --no-update-rc',
    cmd = 'FZF', func = 'fzf#*',
  };
  Plug 'ibhagwan/fzf-lua' {
    event = { 'VeryLazy', 'CmdlineEnter' },
    config = require('config.fzf').setup,
  };
  Plug 'rking/ag.vim' { func = 'ag#*', lazy = true };

  -- Telescope (config/telescope.lua)
  Plug 'nvim-telescope/telescope.nvim' {
    enabled = vim.fn.has('nvim-0.9.0') > 0,
    event = 'CmdlineEnter',
    config = function()
      require('config.telescope').setup()
    end,
  };

  -- Terminal
  Plug 'voldikss/vim-floaterm' { event = 'CmdlineEnter' };

  -- Wildmenu
  Plug 'wookayin/wilder.nvim' {
    dependencies = {'romgrk/fzy-lua-native'},
    cond = has_py3,
    build = UpdateRemotePlugins,
    event = 'CmdlineEnter',
    func = 'wilder#*',
  };

  -- Explorer
  Plug 'nvim-neo-tree/neo-tree.nvim' {
    branch = 'main',
    version = '>=3.12',
    event = (function()
      -- If any of the startup argument is a directory,
      -- we don't lazy-load neotree so it can hijack netrw.
      if vim.tbl_contains(vim.tbl_map(vim.fn.isdirectory, vim.fn.argv()), 1) then return nil
      else return 'VeryLazy' end
    end)(),
    init = function() vim.g.neo_tree_remove_legacy_commands = 1; end,
    config = require('config.neotree').setup_neotree,
  };

  -- Navigation
  Plug 'vim-voom/VOoM' { cmd = { 'Voom', 'VoomToggle' } };
  Plug 'majutsushi/tagbar' { cmd = { 'Tagbar', 'TagbarOpen', 'TagbarToggle' } };

  -- Quickfix
  Plug 'kevinhwang91/nvim-bqf' { ft = 'qf', config = require('config.quickfix').setup_bqf };

  -- Marks and Signs
  Plug 'kshenoy/vim-signature' {
    event = 'VeryLazy',
    config = function()
      -- hlgroups are registered on VimEnter, so need to setup after lazy loading
      pcall(vim.fn['signature#utils#SetupHighlightGroups'])
    end
  };
  Plug 'vim-scripts/errormarker.vim' { event = 'VeryLazy' };
}
