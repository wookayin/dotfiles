-- LSP, completions, and language-specific plugins

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

local LspSetup = 'User LspSetup'

local function has(f) return vim.fn.has(f) > 0 end
local has_py3 = function(p) return require('config.pynvim')() end

-- Register LspSetup, triggered much after VimEnter and VeryLazy plugins.
vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  once = true,
  callback = vim.schedule_wrap(function()
    vim.cmd('doautocmd ' .. LspSetup)
  end)
})

return {
  Plug 'SirVer/ultisnips' {
    cond = has_py3,  -- no rplugin, but need to check python version
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
  Plug 'nvimtools/none-ls.nvim' { event = LspSetup, config = require('config.lsp').setup_null_ls };
  Plug 'nvim-lua/lsp-status.nvim' { event = LspSetup, config = require('config.lsp').setup_lsp_status };
  Plug 'j-hui/fidget.nvim' { branch = 'legacy', event = LspSetup, config = require('config.lsp').setup_fidget };
  Plug 'folke/trouble.nvim' { event = LspSetup, config = require('config.lsp').setup_trouble };
  Plug 'SmiteshP/nvim-navic' { event = LspSetup, config = require('config.lsp').setup_navic };

  Plug 'kyazdani42/nvim-web-devicons' { lazy = true };
  Plug 'onsails/lspkind-nvim' { lazy = true };

  -- Completion
  Plug 'hrsh7th/nvim-cmp' {
    commit = '5260e5e',  -- 2024-05-17
    event = 'InsertEnter',  -- or required by config/lsp.lua
    dependencies = {
      Plug 'hrsh7th/cmp-buffer';
      Plug 'hrsh7th/cmp-nvim-lsp';
      Plug 'hrsh7th/cmp-path';
      Plug 'hrsh7th/cmp-omni';
      Plug 'quangnguyen30192/cmp-nvim-ultisnips' { cond = has_py3 };
      Plug 'tamago324/cmp-zsh';
      Plug 'petertriho/cmp-git';
    },
    config = require('config.completion').setup_cmp,
  };

  -- Formatting
  Plug 'stevearc/conform.nvim' {
    version = '>=5.0',
    config = require('config.formatting').setup,
  };

  -- DAP
  Plug 'mfussenegger/nvim-dap' {
    event = 'VeryLazy',
    cmd = { 'DebugStart', 'DebugContinue' };
    dependencies = {
      Plug 'rcarriga/nvim-dap-ui' { version = '>=4.0' };
      Plug 'rcarriga/cmp-dap';
      Plug 'theHamsta/nvim-dap-virtual-text';
      Plug 'Weissle/persistent-breakpoints.nvim';
      Plug 'mfussenegger/nvim-dap-python';
      Plug 'jbyuki/one-small-step-for-vimkind';
    },
    config = function()
      require('config.dap').setup()
    end,
  };

  -- Python
  Plug 'wookayin/semshi' {
    ft = 'python',
    cond = has_py3,
    config = function()
      -- Semshi uses FileType autocmds on init. Have it called once again when lazy loaded.
      vim.cmd [[ doautocmd SemshiInit FileType python ]]
    end,
    build = UpdateRemotePlugins,
  };
  Plug 'wookayin/vim-autoimport' { cond = has_py3, ft = 'python' };

  -- Other languages
  Plug 'editorconfig/editorconfig-vim' { cond = not has('nvim') };
  Plug 'sheerun/vim-polyglot' { version = 'v4.2.1' };
  Plug 'vmchale/just-vim' { ft = 'just' };
  Plug 'tmux-plugins/vim-tmux' { ft = 'tmux' };
  Plug 'fladson/vim-kitty' { ft = 'kitty' };
  Plug 'lervag/vimtex' { init = require('config.tex').init, config = require('config.tex').setup };
  Plug 'machakann/vim-Verdin' { ft = 'vim' };
  Plug 'gisraptor/vim-lilypond-integrator' { ft = 'lilypond' };
  Plug 'tfnico/vim-gradle' { ft = 'gradle' };
  Plug 'Tyilo/applescript.vim' { ft = 'applescript' };
  Plug 'rdolgushin/groovy.vim' { ft = 'groovy' };
  Plug 'NoahTheDuke/vim-just' { ft = 'just' };

  -- Lua REPL
  Plug 'ii14/neorepl.nvim' { lazy = true };  -- :LuaREPL

  -- Build
  Plug 'skywind3000/asyncrun.vim' { event = 'VeryLazy' };

  -- Testing
  Plug 'nvim-neotest/neotest' {
    version = '>=5.0',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neotest/nvim-nio',
      'antoinemadec/FixCursorHold.nvim',
      Plug 'nvim-neotest/neotest-plenary';
      Plug 'nvim-neotest/neotest-python';
    },
    event = 'VeryLazy',
    config = require('config.testing').setup,
  };
}
