-- Treesitter plugins.

local Plug = require('utils.plug_utils').Plug
local function has(f) return vim.fn.has(f) > 0 end

local treesitter_version
-- Use the old, stable version that is compatible with the minimum supported neovim veriso>
-- There are often a lot of breaking changes in treesitter;
-- when versions bumped up, check whether treesitter highlighter works OK.
-- When `query: invalid node type` error happens, run :TSUpdate or :TSInstall! [lang] manu>
-- see https://github.com/nvim-treesitter/nvim-treesitter/issues/3092
if not has('nvim-0.10') then
  treesitter_version = '*'  -- Use the latest stable version (0.9.0), works for neovim 0.8+
else
  treesitter_version = nil  -- Use the 'master' branch.
end

return {
  Plug 'nvim-treesitter/nvim-treesitter' {
    name = 'nvim-treesitter',
    version = treesitter_version,
    branch = (treesitter_version == nil) and 'master' or nil,
    build = function(_)
      -- :TSUpdateSync (blocks UI)
      (require('nvim-treesitter.install').update { with_sync = true })()
    end,
    event = 'UIEnter',  -- lazy, or on demand (vim.treesitter)
    config = function()
      -- Note: this works as a script, not as a module
      require('config.treesitter')
    end
  };

  Plug 'nvim-treesitter/playground' {
    name = 'nvim-treesitter-playground',
    cmd = { 'TSPlaygroundToggle', 'TSHighlightCapturesUnderCursor' },
    commit = '4044b53',
  };
}
