-- Keymap related plugins (cmds, etc.)
---@diagnostic disable: missing-fields

local Plug = require('utils.plug_utils').Plug
local PlugConfig = require('utils.plug_utils').PlugConfig

return {
  -- Keymaps
  Plug 'junegunn/vim-peekaboo' { event = 'VeryLazy' };
  Plug 'folke/which-key.nvim' {
    event = 'VeryLazy',
    opts = {
      window = { border = "single", winblend = 10 },
      layout = { height = { min = 4, max = 8 } },
    }
    --hi WhichKeyFloat  guibg=#1a2a3a
  };

  -- Actions and operators
  Plug 'Lokaltog/vim-easymotion' { keys = '<leader>f' };
  Plug 'junegunn/vim-easy-align' {
    keys = { '<Plug>(EasyAlign)', { '<Plug>(EasyAlign)', mode = 'v' } },
  };
  Plug 'tpope/vim-surround' { event = 'VeryLazy' };
  Plug 'tpope/vim-repeat' { lazy = true, func = 'repeat#*' };
  Plug 'haya14busa/vim-asterisk' { init = PlugConfig, event = 'VeryLazy' };
  Plug 'unblevable/quick-scope' {
    keys = { 'f', 'F', 't', 'T'}
  };
  Plug 't9md/vim-quickhl' {
    keys = {
      { '<leader>*', '<Plug>(quickhl-manual-this)', mode = { 'n', 'x' } },
      { '<leader>8', '<Plug>(quickhl-manual-reset)', mode = { 'n', 'x' } },
    },
  };

  -- Undo
  Plug 'sjl/gundo.vim' { enabled = false };  -- TODO: Use mundo
  Plug 'machakann/vim-highlightedundo' {
    cond = vim.fn.executable('diff') > 0,
    init = PlugConfig,
    keys = {
      '<Plug>(highlightedundo-undo)', '<Plug>(highlightedundo-redo)', '<Plug>(highlightedundo-Undo)',
      '<Plug>(highlightedundo-gminus)', '<Plug>(highlightedundo-gplus)'
    },
  };
}
