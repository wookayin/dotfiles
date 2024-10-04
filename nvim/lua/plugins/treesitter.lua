-- Treesitter plugins.

local Plug = require('utils.plug_utils').Plug
local function has(f) return vim.fn.has(f) > 0 end

local treesitter_version
-- Use the old, stable version that is compatible with the minimum supported neovim verison
-- There are often a lot of breaking changes in treesitter;
-- when versions bumped up, check whether treesitter highlighter works OK.
-- When `query: invalid node type` error happens, run :TSUpdate or :TSInstall! [lang] manu>
-- see https://github.com/nvim-treesitter/nvim-treesitter/issues/3092
if has('nvim-0.9.2') then
  treesitter_version = nil  -- Use the 'master' branch (0.x versions); not 'main' (1.x)
end

return {
  Plug 'nvim-treesitter/nvim-treesitter' {
    version = treesitter_version, -- master, must be >0.9.2
    branch = (treesitter_version == nil) and 'master' or nil,
    build = function(_)
      -- :TSUpdateSync (blocks UI)
      (require('nvim-treesitter.install').update { with_sync = true })()
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
