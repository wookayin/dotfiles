-- Treesitter plugins.

local Plug = require('utils.plug_utils').Plug
local function has(f) return vim.fn.has(f) > 0 end

local treesitter_version
-- Use the old, stable version that is compatible with the minimum supported neovim verison
-- There are often a lot of breaking changes in treesitter;
-- when versions bumped up, check whether treesitter highlighter works OK.
-- When `query: invalid node type` error happens, run :TSUpdate or :TSInstall! [lang] manu>
-- see https://github.com/nvim-treesitter/nvim-treesitter/issues/3092
if has('nvim-0.9.1') then
  treesitter_version = nil  -- Use the 'master' branch (0.x versions); not 'main' (1.x)
else
  -- for neovim 0.8, need to pin at v0.9.1 otherwise it will not work on master
  -- Use the latest stable version, see nvim-treesitter/nvim-treesitter#5234
  treesitter_version = 'v0.9.1'
end

return {
  Plug 'nvim-treesitter/nvim-treesitter' {
    name = (treesitter_version == nil) and 'nvim-treesitter' or 'nvim-treesitter-0.9.1',
    version = treesitter_version,
    branch = (treesitter_version == nil) and 'master' or nil,
    build = function(_)
      -- :TSUpdateSync (blocks UI)
      (require('nvim-treesitter.install').update { with_sync = true })()
    end,
    event = 'VeryLazy',  -- lazy, or on demand (vim.treesitter call) via ftplugin
    config = function()
      require('config.treesitter').setup()
    end
  };

  Plug 'nvim-treesitter/playground' {
    name = 'nvim-treesitter-playground',
    enabled = not has('nvim-0.10'),
    cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
    commit = '4044b53',
  };
}
