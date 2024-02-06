-- vim-xtabline

local M = {}

local highlight = function(...) vim.api.nvim_set_hl(0, ...) end


M.init_xtabline = function()
  vim.g.xtabline_settings = {
    -- Use 'buffers' as the default xtabline mode, but show 'tabs' if #tabs >= 2
    -- since we use global statusline (laststatus = 3)
    tabline_modes = { 'buffers', 'tabs', 'arglist' },
    -- always show the current xtabline mode
    mode_labels = 'all',
    -- if true, show whether [W]indow or [T]ab local cwd is set
    wd_type_indicator = false,

    --[[ Buffers ]]
    -- 1: buffer numbers, 2: buffer index (position).
    buffer_format = 1,
    -- Do not filter buffers in the list based on directory.
    buffer_filtering = 0,
  }
end

M.setup_xtabline = function()
  require("utils.rc_utils").RegisterHighlights(function()
    -- background filler
    highlight('XTFill',       { bg = '#21212e' })
    -- selected (the current buffer)
    highlight('XTNumSel',     { bg = '#1f2c3d', fg = 'white', bold = true })
    highlight('XTSelect',     { bg = '#ffffff', fg = '#c92a2a', bold = true })
    -- buffer: currently shown in other window
    highlight('XTNum',        { bg = 'black',   fg = 'white', })
    highlight('XTVisible',    { bg = '#cccccc', fg = '#a01a1a' })
    -- buffer: loaded but hidden (including tabs)
    highlight('XTHidden',     { bg = '#333333', fg = '#d9d9d9' })
    highlight('XTHiddenMod',  { bg = '#333333', fg = '#af0000' })

    highlight('XTCorner',     { link = 'Special' })
    highlight('XTSpecial',    { link = 'XTExtra' })
  end)

  -- Show 'tabs' when #tabs >= 2; otherwise show buffers.
  local change_xtabline_mode = function()
    if vim.fn.tabpagenr('$') >= 2 then
      vim.cmd.XTabMode { args = {'tabs'}, mods = { silent = true }, }
    else
      vim.cmd.XTabMode { args = {'buffers'}, mods = { silent = true }, }
    end
  end
  change_xtabline_mode()
  vim.api.nvim_create_autocmd({'TabNew', 'TabClosed'}, {
    group = vim.api.nvim_create_augroup('xtabline-hybrid', { clear = true }),
    callback = change_xtabline_mode,
  })

  -- Keymaps and commands
  vim.keymap.set('n', '<leader>bH', '<cmd>XTabMoveBufferPrev<CR>')
  vim.keymap.set('n', '<leader>bL', '<cmd>XTabMoveBufferNext<CR>')
  vim.fn.CommandAlias('bmove', 'XTabMoveBuffer')
end


-- Resourcing support
if ... == nil then
  M.setup_xtabline()
end

return M
