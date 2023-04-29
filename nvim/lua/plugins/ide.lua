-- LSP, completions, and language-specific plugins

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig
local UpdateRemotePlugins = require('utils.plug_utils').UpdateRemotePlugins

local function has(f) return vim.fn.has(f) > 0 end
local has_py36 = has('python3') and vim.fn.py3eval('sys.version_info >= (3, 6)') == true

return {
  Plug 'Sirver/ultisnips' {
    cond = has('python3'),
  };

  -- LSP
  Plug 'neovim/nvim-lspconfig';
  Plug 'williamboman/mason.nvim';
  Plug 'williamboman/mason-lspconfig.nvim';
  Plug 'folke/neodev.nvim';
  Plug 'jose-elias-alvarez/null-ls.nvim';

  Plug 'ray-x/lsp_signature.nvim';
  Plug 'nvim-lua/lsp-status.nvim';
  Plug 'j-hui/fidget.nvim';
  Plug 'folke/trouble.nvim';
  Plug 'kyazdani42/nvim-web-devicons';
  Plug 'onsails/lspkind-nvim';

  -- Completion
  Plug 'hrsh7th/nvim-cmp' {
    commit = '4c05626',
  };
  Plug 'hrsh7th/cmp-buffer';
  Plug 'hrsh7th/cmp-nvim-lsp';
  Plug 'hrsh7th/cmp-path';
  Plug 'quangnguyen30192/cmp-nvim-ultisnips';
  Plug 'tamago324/cmp-zsh';
  Plug 'petertriho/cmp-git';

  -- Python
  Plug 'wookayin/semshi' { cond = has('python3'), build = UpdateRemotePlugins };
  Plug 'stsewd/isort.nvim' { cond = has('python3'), build = UpdateRemotePlugins };
  Plug 'wookayin/vim-autoimport' { cond = has('python3') };
  Plug 'klen/python-mode' { cond = has('python3'), branch = 'develop' };
  Plug 'wookayin/vim-python-enhanced-syntax';

  -- Other languages
  Plug 'editorconfig/editorconfig-vim';
  Plug 'sheerun/vim-polyglot' { version = 'v4.2.1' };
  Plug 'tmux-plugins/vim-tmux';
  Plug 'fladson/vim-kitty' { ft = 'kitty' };
  Plug 'vim-pandoc/vim-pandoc' { init = PlugConfig };
  Plug 'vim-pandoc/vim-pandoc-syntax';
  Plug 'lervag/vimtex' { ft = {'tex', 'plaintex'} };
  Plug 'machakann/vim-Verdin' { ft = 'vim' };
  Plug 'gisraptor/vim-lilypond-integrator';
  Plug 'tfnico/vim-gradle' { ft = 'gradle' };
  Plug 'Tyilo/applescript.vim' { ft = 'applescript' };
  Plug 'rdolgushin/groovy.vim' { ft = 'groovy' };

  -- Build
  Plug 'neomake/neomake';
  Plug 'skywind3000/asyncrun.vim';

  -- Testing
  Plug 'nvim-neotest/neotest' {
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'antoinemadec/FixCursorHold.nvim'
    },
  };
  Plug 'nvim-neotest/neotest-plenary';
  Plug 'nvim-neotest/neotest-python';
}
