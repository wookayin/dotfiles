-- Neovim init config
-- ~/.config/nvim/init.lua
--
-- Jongwook Choi (@wookayin)
-- https://dotfiles.wook.kr


-- The global namespace for config-related stuffs.
RC = {}

function RC.should_resource()
  -- true only if called in a top-level via :source or :luafile (not require)
  return vim.v.vim_did_enter > 0 and #vim.split(debug.traceback(), '\n') <= 3
end

-- require a lua module, but force reload it (RC files can be re-sourced)
function _require(name)
  package.loaded[name] = nil
  return require(name)
end

-- Configure neovim python host.
require 'config.pynvim'
require 'config.fixfnkeys'

-- VimR support
-- @see https://github.com/qvacua/vimr/wiki#initvim
if vim.fn.has('gui_vimr') > 0 then
  vim.cmd [[
    set termguicolors
    set title
  ]]
end

-- Workaround for neovim 0.9.0+: Suppress deprecation warning
-- Many third-party plugins need migration to the new treesitter API
if vim.fn.has('nvim-0.9') > 0 then
  vim.treesitter.query.get_node_text = vim.treesitter.get_node_text
  vim.treesitter.query.get_query = vim.treesitter.query.get
end


-- Source plain vimrc for basic settings.
-- This should precede plugin loading via lazy.nvim.
vim.cmd [[
  source ~/.vimrc
  set rtp+=~/.vim
]]

-- Check neovim version
if vim.fn.has('nvim-0.8') == 0 then
  vim.cmd [[
    echohl WarningMsg | echom 'This version of neovim is unsupported. Please upgrade to Neovim 0.8.0+ or higher.' | echohl None
  ]]
  return

elseif vim.fn.has('nvim-0.9.1') == 0 then
  vim.defer_fn(function()
    local like_false = function(x) return x == nil or x == "0" or x == "" end
    if not like_false(vim.env.DOTFILES_SUPPRESS_NEOVIM_VERSION_WARNING) then return end
    local msg = 'Please upgrade to latest neovim (0.9.1+).\n'
    msg = msg .. 'Support for neovim <= 0.8.x will be dropped soon.'
    msg = msg .. '\n\n' .. string.format('Try: $ %s install neovim', vim.fn.has('mac') > 0 and 'brew' or 'dotfiles')
    msg = msg .. '\n\n' .. ('If you cannot upgrade yet but want to suppress this warning,\n'
                            .. 'use `export DOTFILES_SUPPRESS_NEOVIM_VERSION_WARNING=1`.')
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.notify(msg, 'error', { title = 'Deprecation Warning', timeout = 5000 })
  end, 100)
end

do
  -- Load all the plugins (lazy.nvim, requires nvim 0.8+)
  require 'config.plugins'

  -- Colorscheme needs to be called AFTER plugins are loaded,
  -- because of the different plugin loading mechanism and order.
  vim.cmd [[ colorscheme xoria256-wook ]]
end

-- Source some individual rc files on startup, manually in sequence.
-- Note that many other config modules are called upon plugin loading.
-- (see each plugin spec, e.g. 'plugins/ui' and 'config/ui')
-- See nvim/lua/config/commands/init.lua
_require 'config.commands'

-- Source local-only lua configs (not git tracked)
if vim.fn.filereadable(vim.fn.expand('~/.config/nvim/lua/config/local.lua')) > 0 then
  require 'config.local'
end
