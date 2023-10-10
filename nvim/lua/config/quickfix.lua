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


--- Toggle quickfix window (either :copen or :cclose),
--- but do not steal the cursor (preserve the current window)!
--- Should work also well even when the current window is floating, etc.
function M.toggle_quickfix()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "quickfix" then
      vim.cmd.cclose()
      return
    end
  end
  vim.cmd.Copen()  -- :Copen might be overridden by ftplugin
end
-- :QuickfixToggle, :CToggle
vim.api.nvim_create_user_command('QuickfixToggle', function(e) M.toggle_quickfix() end, { bar = true })
vim.api.nvim_create_user_command('CToggle', function(e) M.toggle_quickfix() end, { bar = true })


--- Like :copen, but do not steal the cursor.
--- @param opts? table  mods: string?, count: integer?, height: integer?
function M.open_quickfix(opts)
  opts = vim.tbl_extend("force", {}, opts or {})
  opts.mods = (opts.mods and opts.mods ~= "") and opts.mods or 'botright'
  opts.count = (opts.count and opts.count ~= 0) and opts.count or ''

  local current_win = vim.api.nvim_get_current_win()
  vim.cmd(([[ %s %scopen %s ]]):format(opts.mods, opts.count, opts.height or ''))

  -- Move back to the previous window, so that the cursor is not stolen by quickfix
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end
-- :Copen, :[modifier] [count]Copen [height]
vim.api.nvim_create_user_command('Copen', function(e)
  M.open_quickfix({ height = e.args, mods = e.mods, count = e.count })
end, { bar = true, count = true, nargs = '?' })


-- Resourcing support
if RC and RC.should_resource() then
  M.setup_bqf()
end

(RC or {}).quickfix = M
return M
