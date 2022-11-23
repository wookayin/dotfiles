-- Neovim init config
-- ~/.config/nvim/init.lua
--
-- Jongwook Choi (@wookayin)
-- https://dotfiles.wook.kr


-- The global namespace for config-related stuffs.
RC = {}

-- Configure neovim python host.
require 'config/pynvim'
require 'config/fixfnkeys'

-- VimR support
-- @see https://github.com/qvacua/vimr/wiki#initvim
if vim.fn.has('gui_vimr') > 0 then
  vim.cmd [[
    set termguicolors
    set title
  ]]
end

-- Source plain vimrc for basic settings.
vim.cmd [[
  source ~/.vimrc
  set rtp+=~/.vim
]]

-- Check neovim version
if vim.fn.has('nvim-0.7') == 0 then
  vim.cmd [[
    echohl WarningMsg | echom 'This version of neovim is unsupported. Please upgrade to Neovim 0.7.0+ or higher.' | echohl None
  ]]
  return
end

-- require a lua module, but force reload it (RC files can be re-sourced)
function _require(name)
  package.loaded[name] = nil
  return require(name)
end

_require 'config/ui'
_require 'config/commands'
_require 'config/quickfix'

-- Source individiual rc files. (lazy loading)
function RC.source_config_lazy()
  _require 'config/statusline'
  _require 'config/lsp'
  _require 'config/treesitter'
  _require 'config/telescope'
  _require 'config/git'
  _require 'config/folding'
  _require 'config/testing'
end
vim.cmd [[
  autocmd User LazyInit  lua RC.source_config_lazy()
]]

-- Source local-only lua configs (not git tracked)
if vim.fn.filereadable(vim.fn.expand('~/.config/nvim/lua/config/local.lua')) > 0 then
  require 'config/local'
end
