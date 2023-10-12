-- Config for nvim-ufo

local M = {}

local ufo


M.setup_ufo = function()
  ufo = require('ufo')

  -- This is required by nvim-ufo (see kevinhwang91/nvim-ufo#30, kevinhwang91/nvim-ufo#57)
  -- otherwise folds will be unwantedly open/closed when nvim-ufo is in action
  vim.o.foldlevel = 99
  vim.o.foldlevelstart = 99
  vim.g.has_folding_ufo = 1

  -- See $VIMPLUG/nvim-ufo/lua/ufo/config.lua
  -- See https://github.com/kevinhwang91/nvim-ufo/blob/master/README.md#setup-and-description
  ufo.setup {
    open_fold_hl_timeout = 150,
    provider_selector = function(bufnr, filetype)
      -- Use treesitter if available
      if pcall(require, 'nvim-treesitter.parsers') then
        if require("nvim-treesitter.parsers").has_parser(filetype) then
          return {'treesitter', 'indent'}
        end
      end

      -- Otherwise, might need to disable 'fold providers'
      -- so that we can fallback to the default vim's folding behavior (per foldmethod).
      -- This can be also helpful for a bug where all open/closed folds are lost and reset
      -- whenever fold is updated when, for instance, saving the buffer (when foldlevel != 99).
      -- For more details, see kevinhwang91/nvim-ufo#30
      return ''
    end,

    -- see #26, #38, #74 (enables ctx.end_virt_text)
    enable_get_fold_virt_text = true,

    fold_virt_text_handler = M.virtual_text_handler,
  }
end

-- (highlighted) preview of folded region. returns List[ Tuple[Message, Highlight] ]
-- Preview, # of folded lines,
-- Part of code brought from #38, credit goes to @ranjithshegde
M.virtual_text_handler = function(virt_text, lnum, end_lnum, width, truncate, ctx)

  local counts = ("  (󰁂 %d lines)"):format(end_lnum - lnum + 1)
  local ellipsis = "⋯"
  local padding = ""

  local bufnr = vim.api.nvim_get_current_buf()
  local end_text = vim.api.nvim_buf_get_lines(bufnr, end_lnum - 1, end_lnum, false)[1]
  local end_virt_text = ctx.get_fold_virt_text(end_lnum)

  -- Summarization of the folded text (optional)
  local folding_summary = M.get_fold_summary(lnum, end_lnum, ctx)
  if folding_summary and #folding_summary > 0 then
    table.insert(virt_text, { "  " .. folding_summary, "MoreMsg" })
  end

  -- Post-process end line: show only if it's a single word and token
  -- e.g., { ... }  ( ... )  [{( ... )}]  function() .. end
  -- Trim leading whitespaces in end_virt_text
  if #end_virt_text >= 1 and vim.trim(end_virt_text[1][1]) == "" then
    table.remove(end_virt_text, 1)      -- e.g., {"   ", ")"} -> {")"}
  end
  if #end_virt_text == 1 and #vim.split(vim.trim(end_text), " ") == 1 then
    end_virt_text[1][1] = vim.trim(end_virt_text[1][1])  -- trim the first token, e.g., "   }" -> "}"
    end_virt_text = { end_virt_text[1] }  -- show only the first token
  else
    end_virt_text = {}
  end

  -- Process virtual text, with some truncation
  local sufWidth = (2 * vim.fn.strdisplaywidth(ellipsis)) + vim.fn.strdisplaywidth(counts)
  for _, v in ipairs(end_virt_text) do
    sufWidth = sufWidth + vim.fn.strdisplaywidth(v[1])
  end

  local target_width = width - sufWidth
  local cur_width = 0

  local result = {}  -- virtual text tokens to display.

  for _, chunk in ipairs(virt_text) do
    local chunk_text = chunk[1]

    local chunk_width = vim.fn.strdisplaywidth(chunk_text)
    if target_width > cur_width + chunk_width then
      table.insert(result, chunk)
    else
      chunk_text = truncate(chunk_text, target_width - cur_width)
      local hl_group = chunk[2]
      table.insert(result, { chunk_text, hl_group })
      chunk_width = vim.fn.strdisplaywidth(chunk_text)

      if cur_width + chunk_width < target_width then
        padding = padding .. (" "):rep(target_width - cur_width - chunk_width)
      end
      break
    end
    cur_width = cur_width + chunk_width
  end

  table.insert(result, { "  " .. ellipsis .. "  ", "UfoFoldedEllipsis" })

  for _, v in ipairs(end_virt_text) do
    table.insert(result, v)
  end

  table.insert(result, { counts, "MoreMsg" })
  table.insert(result, { padding, "" })

  return result
end

-- 1-line summary of the folded region (coming before ellipsis).
-- Useful to have filetype-specific customizations here.
M.get_fold_summary = function(lnum, end_lnum, ctx)
  local filetype = vim.bo.filetype
  local bufnr = vim.api.nvim_get_current_buf()

  if filetype == 'bib' then
    -- bibtex: Parse title = ... entry
    for l = lnum, end_lnum do
      local line_string = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1]
      local m = line_string:gmatch("title%s*=%s*{(.*)}")()
      if m then
        return m
      end
    end
  end

  return ""
end

-- Keymaps for nvim-ufo
-- Most of fold-related keys such as zR, zM, etc. need to be remapped
-- because nvim-ufo overrides most of fold operations and foldlevel.

M.attach_ufo_if_necessary = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not ufo.hasAttached(bufnr) then
    ufo.attach()
    return true
  end
  return false
end

M.enable_ufo_fold = function()
  vim.wo.foldenable = true
  vim.wo.foldlevel = 99   -- sometimes get lost. Ensure to be 99 at all times (see kevinhwang91/nvim-ufo#89)
  M.attach_ufo_if_necessary()  -- some buffers may not have been attached
  ufo.enableFold()   -- setlocal foldenable
end


-- Open/Close fold
-- Note: z<space> ==> see vimrc
M.open_all_folds = function()  -- zR
  M.enable_ufo_fold()
  ufo.openAllFolds()
end
M.close_all_folds = function()  -- zM
  M.enable_ufo_fold()
  ufo.closeAllFolds()
end
M.reduce_folding = function()  -- zr
  M.enable_ufo_fold()
  ufo.closeFoldsWith()
end
M.more_folding = function()  -- zm
  M.enable_ufo_fold()
  ufo.openFoldsExceptKinds()
end

-- Peek/preview a closed fold.
M.peek_folded_lines = function()
  local enter = false
  local include_next_line = false
  ufo.peekFoldedLinesUnderCursor(enter, include_next_line)
end

function M.setup_folding_keymaps()
  vim.keymap.set('n', 'zR', M.open_all_folds,  {desc='ufo - open all folds'})
  vim.keymap.set('n', 'zM', M.close_all_folds, {desc='ufo - close all folds'})
  vim.keymap.set('n', 'zr', M.reduce_folding,  {desc='ufo - reduce fold (zr)'})
  vim.keymap.set('n', 'zm', M.more_folding,    {desc='ufo - fold more (zm)'})
  vim.keymap.set('n', 'zp', M.peek_folded_lines, {desc='ufo - peek and preview folded lines'})
end


function M.setup()
  M.setup_ufo()
  M.setup_folding_keymaps()

  -- Workaround for neovim/neovim#20726: Ctrl-C on terminal can make neovim hang
  vim.cmd [[
    augroup terminal_disable_fold
      autocmd!
      autocmd TermOpen * setlocal foldmethod=manual
    augroup END
  ]]
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end

(RC or {}).folding = M
return M
