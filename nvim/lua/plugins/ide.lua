-- LSP, completions, and language-specific plugins

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

local function has(f) return vim.fn.has(f) > 0 end
local LspSetup = 'User LspSetup'

-- Register LspSetup after UIEnter
vim.api.nvim_create_autocmd('UIEnter', {
  pattern = '*',
  once = true,
  callback = vim.schedule_wrap(function()
    vim.cmd('doautocmd ' .. LspSetup)
  end)
})

return {
  Plug 'Sirver/ultisnips' {
    cond = has('python3'),
    event = { 'InsertEnter', 'CmdlineEnter' },
  };

  -- LSP (lazy loaded, see config/lsp.lua)
  Plug 'neovim/nvim-lspconfig' {
    event = LspSetup,
    dependencies = { 'mason.nvim' },
    config = require('config.lsp').setup_lsp, -- mason, lspconfig, etc.
  };
  Plug 'williamboman/mason.nvim' {
    event = LspSetup, -- as a dependency for nvim-lspconfig
    dependencies = {
      Plug 'williamboman/mason-lspconfig.nvim';
    },
  };
  Plug 'folke/neodev.nvim' { event = LspSetup };
  Plug 'ray-x/lsp_signature.nvim' { event = LspSetup };
  Plug 'WhoIsSethDaniel/toggle-lsp-diagnostics.nvim' { lazy = true };
  Plug 'jose-elias-alvarez/null-ls.nvim' { event = LspSetup, config = require('config.lsp').setup_null_ls };
  Plug 'nvim-lua/lsp-status.nvim' { event = LspSetup, config = require('config.lsp').setup_lsp_status };
  Plug 'j-hui/fidget.nvim' { event = LspSetup, config = require('config.lsp').setup_fidget };
  Plug 'folke/trouble.nvim' { event = LspSetup, config = require('config.lsp').setup_trouble };
  Plug 'SmiteshP/nvim-navic' { event = LspSetup, config = require('config.lsp').setup_navic };

  Plug 'kyazdani42/nvim-web-devicons' { lazy = true };
  Plug 'onsails/lspkind-nvim' { lazy = true };

  -- Completion
  Plug 'hrsh7th/nvim-cmp' {
    commit = '4c05626',
    event = 'InsertEnter',  -- or required by config/lsp.lua
    dependencies = {
      Plug 'hrsh7th/cmp-buffer';
      Plug 'hrsh7th/cmp-nvim-lsp';
      Plug 'hrsh7th/cmp-path';
      Plug 'quangnguyen30192/cmp-nvim-ultisnips';
      Plug 'tamago324/cmp-zsh';
      Plug 'petertriho/cmp-git';
    },
    config = require('config.lsp').setup_cmp,
  };

  -- Python
  Plug 'wookayin/semshi' {
    cond = has('python3'), ft = 'python',
    config = function()
      -- Semshi uses FileType autocmds on init. Have it called once again when lazy loaded.
      vim.cmd [[ doautocmd SemshiInit FileType python ]]
    end,
    build = UpdateRemotePlugins,
  };
  Plug 'stsewd/isort.nvim' { cond = has('python3'), ft = 'python', build = UpdateRemotePlugins };
  Plug 'wookayin/vim-autoimport' { cond = has('python3'), ft = 'python' };
  Plug 'klen/python-mode' { cond = has('python3'), branch = 'develop', ft = 'python' };
  Plug 'wookayin/vim-python-enhanced-syntax' { ft = 'python' };

  -- Other languages
  Plug 'editorconfig/editorconfig-vim';
  Plug 'sheerun/vim-polyglot' { version = 'v4.2.1' };
  Plug 'tmux-plugins/vim-tmux' { ft = 'tmux' };
  Plug 'fladson/vim-kitty' { ft = 'kitty' };
  Plug 'vim-pandoc/vim-pandoc' { ft = { 'pandoc', 'markdown' }, init = PlugConfig };
  Plug 'vim-pandoc/vim-pandoc-syntax' { ft = { 'pandoc', 'markdown' } };
  Plug 'lervag/vimtex' { ft = { 'tex', 'plaintex' }, func = 'vimtex#*' };
  Plug 'machakann/vim-Verdin' { ft = 'vim' };
  Plug 'gisraptor/vim-lilypond-integrator' { ft = 'lilypond' };
  Plug 'tfnico/vim-gradle' { ft = 'gradle' };
  Plug 'Tyilo/applescript.vim' { ft = 'applescript' };
  Plug 'rdolgushin/groovy.vim' { ft = 'groovy' };

  -- Lua REPL
  Plug 'ii14/neorepl.nvim' { lazy = true };  -- :LuaREPL

  -- Build
  Plug 'neomake/neomake' { event = 'CmdlineEnter' };
  Plug 'skywind3000/asyncrun.vim' { event = 'UIEnter' };

  -- Testing
  Plug 'nvim-neotest/neotest' {
    dependencies = {
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      Plug 'nvim-neotest/neotest-plenary';
      Plug 'nvim-neotest/neotest-python';
    },
    event = 'UIEnter',
    config = require('config.testing').setup,
  };
}
