-- config for latex and vimtex
-- See doc: $VIMPLUG/vimtex/doc/vimtex.txt
-- See also ~/.config/nvim/after/ftplugin/tex.lua
-- See also ~/.config/nvim/after/ftplugin/tex.vim

local M = {}

-- Options that need to be set before packadd.
-- :help vimtex-options
function M.init()
  -- Always prefer latex instead of plaintex, etc. (:h vimtex-tex-flavor)
  vim.g.tex_flavor = 'latex'

  -- Use treesitter highlights for tex, see ~/.vim/after/syntax/tex.vim
  vim.g.vimtex_syntax_enabled = 0

  -- suppress version warning
  vim.g.vimtex_disable_version_warning = 1

  -- Disable neovim's popup window for user prompt,
  -- the popup window blocks the UI in an unpleasant way
  vim.g.vimtex_ui_method = {
    confirm = 'legacy',
    input = 'legacy',
    select = 'legacy',
  }
end

--- Configs that can be set after the plugin is loaded.
function M.setup()
  M._setup_viewer()
end

-- in macOS, use Skim as the default LaTeX PDF viewer (for vimtex)
-- for :Vimtexview, move Skim's position to where the cursor currently points to.
function M._setup_viewer()
  if vim.fn.has('mac') > 0 then
    local has_texshop = (
      vim.fn.isdirectory('/Applications/TeX/TeXShop.app') > 0 or
      vim.fn.isdirectory('/Applications/TeXShop.app') > 0
    )
    if vim.fn.executable('texshop') > 0 and has_texshop then
      -- ~/.dotfiles/bin/texshop
      vim.g.vimtex_view_general_viewer = 'texshop'
    else
      -- Skim.app
      vim.g.vimtex_view_general_viewer = '/Applications/Skim.app/Contents/SharedSupport/displayline'
      vim.g.vimtex_view_general_options = '-r -g @line @pdf @tex'
    end
  end
end

return M
