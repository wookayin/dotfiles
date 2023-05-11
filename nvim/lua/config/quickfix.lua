-- config/quickfix.lua

local M = {}

-- [[ Useful commands and keys (https://github.com/kevinhwang91/nvim-bqf#function-table)
--     zf: Enter the fzf search mode
-- ]]


function M.setup_bqf()
  -- https://github.com/kevinhwang91/nvim-bqf#setup-and-description
  -- https://github.com/kevinhwang91/nvim-bqf#advanced-configuration
  require "bqf".setup {
    auto_enable = true,

    preview = {
      should_preview_cb = function(bufnr, qf_winid)
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match('^fugitive://') then return false end
        return true
      end,
    },

    func_map = {
      -- Do not map <C-b> <C-f> in the quickfix window
      pscrolldown = '',
      pscrollup = '',
    },
  }

  require "utils.rc_utils".RegisterHighlights(function()
    vim.cmd [[

      " use more discernable colors
      highlight!      BqfPreviewFloat       guibg=#1a2a31
      highlight! link BqfPreviewBorder      BqfPreviewFloat
      " do not highlight cursors in the preview window
      highlight! link BqfPreviewCursor      BqfPreviewFloat

    ]]
  end)

  -- Custom commands (local) on the quickfix windowfix window
  vim.cmd [[
    augroup bqfQuickfixWindow
      autocmd!
      " :FZF, :Grep, :Filter (zf) actions
      autocmd FileType qf command! -buffer  FZFQuickfix  lua require('bqf.filter.fzf').run()
      autocmd FileType qf command! -buffer  Grep         FZFQuickfix
      autocmd FileType qf command! -buffer  FZF          FZFQuickfix
      autocmd FileType qf command! -buffer  Filter       FZFQuickfix

      " :Clean
    augroup END
  ]]
end

-- Resourcing support
if vim.v.vim_did_enter > 0 then
  M.setup_bqf()
end

(RC or {}).quickfix = M
return M
