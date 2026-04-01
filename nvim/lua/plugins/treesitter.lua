-- Treesitter plugins.
---@diagnostic disable: missing-fields

local Plug = require('utils.plug_utils').Plug
local function has(f) return vim.fn.has(f) > 0 end

return {
  Plug 'nvim-treesitter/nvim-treesitter' {
    branch = 'main',  -- Compatible with nvim 0.11+, no longer 'master'!
    build = function(_)
      -- Uses blocking call to wait until installation is complete.
      local MINUTE_MS = 1000
      require('nvim-treesitter').update():wait(1 * 60 * 1000)  -- 60 sec
      -- (require('nvim-treesitter.install').update { with_sync = true })()
    end,
    event = 'VeryLazy',  -- lazy, or on demand (vim.treesitter call) via ftplugin
    init = function()
      -- Ensure conda's custom compiler is never used (via $CC);
      -- conda's gcc can make treesitter parsers and neovim crash
      -- Note: this needs to be done in init, before importing nvim-treesitter
      -- See nvim-treesitter/nvim-treesitter#5623
      if vim.fn.executable("/usr/bin/gcc") > 0 then
        vim.env.CC = "/usr/bin/gcc"
        vim.env.GCC = "/usr/bin/gcc"
      end
    end,
    config = function()
      require('config.treesitter').setup()
    end,
  };

  Plug 'nvim-treesitter/playground' {
    name = 'nvim-treesitter-playground',
    enabled = not has('nvim-0.10'),
    cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
    commit = '4044b53',
  };
}
