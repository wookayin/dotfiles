-- Neovim init config
-- ~/.config/nvim/init.lua
--
-- Jongwook Choi (@wookayin)
-- https://dotfiles.wook.kr


-- The global namespace for config-related stuffs.
RC = {}

-- Configure neovim python host.
require 'config/pynvim'

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

-- Source individiual rc files. (lazy loading)
function RC.source_config_lazy()
  require 'config/statusline'
  require 'config/lsp'
  require 'config/treesitter'
  require 'config/telescope'
  require 'config/folding'
  require 'config/testing'
end
vim.cmd [[
  autocmd User LazyInit  lua RC.source_config_lazy()
]]
