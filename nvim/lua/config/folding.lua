-- Config for nvim-ufo

local M = {}

--- Common config for folding;
--- executed no matter what, even if nvim-ufo is disabled.
function M.setup()
  -- Workaround for neovim/neovim#20726: Ctrl-C on terminal can make neovim hang
  vim.cmd [[
    augroup terminal_disable_fold
      autocmd!
      autocmd TermOpen * setlocal foldmethod=manual foldexpr=0
    augroup END
  ]]

  -- highlighted foldtext without nvim-ufo (can be a sane default).
  if vim.fn.has('nvim-0.10') > 0 then
    vim.opt.foldtext = ''
    vim.opt.fillchars:append({ fold = ' ' })
  end
end


M.setup_ufo = function()
  local ufo = require('ufo')

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
        if require("config.treesitter").has_parser(filetype) then
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

    ---@type UfoFoldVirtTextHandler
    fold_virt_text_handler = function(...)
      return require("config.folding").virtual_text_handler(...)
    end,
  }

  M.setup_ufo_keymaps()
end

M.before_ufo = function()
  -- Need to disable zM, zR during init, because it will change foldlevel
  -- if zM/zR executed before the keymap settings of nvim-ufo has been effective.
  local ufo_not_ready = vim.schedule_wrap(function()
    vim.notify("nvim-ufo is yet to be initialized, please try again later...",
      vim.log.levels.WARN, { timeout = 500, title = "nvim-ufo" })
  end)
  vim.keymap.set('n', 'zM', ufo_not_ready, { silent = true })
  vim.keymap.set('n', 'zR', ufo_not_ready, { silent = true })
end


--- (highlighted) preview of folded region.
-- Preview, # of folded lines, etc.
-- Part of code brought from kevinhwang91/nvim-ufo#38, credit goes to @ranjithshegde
---@return UfoExtmarkVirtTextChunk[]  return a list of virtual text chunks: { text, highlight }[].
---@type UfoFoldVirtTextHandler
M.virtual_text_handler = function(virt_text, lnum, end_lnum, width, truncate, ctx)
  local counts = ("  (󰁂 %d lines)"):format(end_lnum - lnum + 1)
  local ellipsis = "⋯"
  local padding = ""

  ---@type string
  local end_text = vim.api.nvim_buf_get_lines(ctx.bufnr, end_lnum - 1, end_lnum, false)[1]
  ---@type UfoExtmarkVirtTextChunk[]
  local end_virt_text = ctx.get_fold_virt_text(end_lnum)

  -- Summarization of the folded text (optional)
  local folding_summary = M.get_fold_summary(virt_text, lnum, end_lnum, ctx)
  if not folding_summary then
  elseif type(folding_summary) == 'string' and #folding_summary > 0 then
    table.insert(virt_text, { "  " .. folding_summary, "MoreMsg" })
  elseif type(folding_summary) == 'table' then
    virt_text = folding_summary  -- replace the entire virt_text
  else error("Unknown type")
  end

  -- Post-process end line: show only if it's a single word and token
  -- e.g., { ⋯ }  ( ⋯ )  [{( ⋯ )}]  function() ⋯ end  foo("bar", { ⋯ })
  -- Trim leading whitespaces in end_virt_text
  if #end_virt_text >= 1 and vim.trim(end_virt_text[1][1]) == "" then
    table.remove(end_virt_text, 1)      -- e.g., {"   ", ")"} -> {")"}
  end

  -- if the end line consists of a single 'word' (not single token)
  -- this could be multiple tokens/chunks, e.g. `end)` `})`
  if #vim.split(vim.trim(end_text), " ") == 1 then
    if end_virt_text[1] ~= nil then
      end_virt_text[1][1] = vim.trim(end_virt_text[1][1])  -- trim the first token, e.g., "   }" -> "}"
    end
  else
    end_virt_text = { }
  end

  -- Process virtual text, with some truncation at virt_text
  local suffixWidth = (2 * vim.fn.strdisplaywidth(ellipsis)) + vim.fn.strdisplaywidth(counts)
  for _, v in ipairs(end_virt_text) do
    suffixWidth = suffixWidth + vim.fn.strdisplaywidth(v[1])
  end
  if suffixWidth > 10 then
    suffixWidth = 10
  end

  local target_width = width - suffixWidth
  local cur_width = 0

  -- the final virtual text tokens to display.
  local result = {}

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

  -- Also truncate end_virt_text to suffixWidth.
  cur_width = 0
  local j = #result
  for i, v in ipairs(end_virt_text) do
    table.insert(result, v)
    cur_width = cur_width + #v[1]
    while cur_width > suffixWidth and j + 1 < #result do
      cur_width = cur_width - #result[j + 1][1]
      result[j + 1][1] = ""
      j = j + 1
    end
  end
  if cur_width > suffixWidth then
   local text = result[#result[1]][1]
    result[#result][1] = truncate(text, suffixWidth)
  end

  table.insert(result, { counts, "MoreMsg" })
  table.insert(result, { padding, "" })

  return result
end

--- Get a 1-line summary of the folded region (coming before ellipsis).
--- Useful to have filetype-specific customizations for foldtext.
---
---@param virt_text UfoExtmarkVirtTextChunk[] the current virtual text in the folded line (lnum)
---@param lnum      integer the start line number (1-indexed)
---@param end_lnum  integer the end line number (1-indexed, inclusive)
---@param ctx       UfoFoldVirtTextHandlerContext
---@return string | UfoExtmarkVirtTextChunk[] | nil
---   If returns string, this will be appended to the existing virt_text.
---   If returns a table (UfoExtmarkVirtTextChunk[]), virt_text will be replaced.
---   If nil, do not append any text in addition to virt_text.
M.get_fold_summary = function(virt_text, lnum, end_lnum, ctx)
  local bufnr = ctx.bufnr
  local filetype = vim.bo[bufnr].filetype

  ---@param line_num integer line number (1-indexed)
  ---@return string|nil
  local read_line = function(line_num)
    return vim.api.nvim_buf_get_lines(bufnr, line_num - 1, line_num, false)[1]
  end

  if filetype == 'bib' then
    -- bibtex: Parse title = ... entry
    for l = lnum, end_lnum do
      local line_string = read_line(l) or ""
      local m = line_string:gmatch("title%s*=%s*{(.*)}")()
      if m then
        return m --[[@as string]]
      end
    end

  elseif filetype == 'lua' then
    -- Skip not so informative first line, and read the next line
    -- Example: `----------------`, `---@private`
    local all_comment_marker = ctx.text:match('^%-+%s*$')
    if all_comment_marker then
      return ctx.get_fold_virt_text(lnum + 1)
    end
  end

  return nil  -- Unknown
end

-- Keymaps for nvim-ufo
-- Most of fold-related keys such as zR, zM, etc. need to be remapped
-- because nvim-ufo overrides most of fold operations and foldlevel.

M.attach_ufo_if_necessary = function()
  local bufnr = vim.api.nvim_get_current_buf()
  if not require("ufo").hasAttached(bufnr) then
    require("ufo").attach()
    return true
  end
  return false
end

M.enable_ufo_fold = function()
  vim.wo.foldenable = true
  vim.wo.foldlevel = 99   -- sometimes get lost. Ensure to be 99 at all times (see kevinhwang91/nvim-ufo#89)
  M.attach_ufo_if_necessary()  -- some buffers may not have been attached
  require("ufo").enableFold()   -- setlocal foldenable
end


-- Open/Close fold
-- Note: z<space> ==> see vimrc
M.open_all_folds = function()  -- zR
  M.enable_ufo_fold()
  require("ufo").openAllFolds()
end
M.close_all_folds = function()  -- zM
  M.enable_ufo_fold()
  require("ufo").closeAllFolds()
end
M.reduce_folding = function()  -- zr
  M.enable_ufo_fold()
  require("ufo").closeFoldsWith()
end
M.more_folding = function()  -- zm
  M.enable_ufo_fold()
  require("ufo").openFoldsExceptKinds()
end

-- Peek/preview a closed fold.
M.peek_folded_lines = function()
  local enter = false
  local include_next_line = false
  require("ufo").peekFoldedLinesUnderCursor(enter, include_next_line)
end

function M.setup_ufo_keymaps()
  vim.keymap.set('n', 'zR', M.open_all_folds,  {desc='ufo - open all folds'})
  vim.keymap.set('n', 'zM', M.close_all_folds, {desc='ufo - close all folds'})
  vim.keymap.set('n', 'zr', M.reduce_folding,  {desc='ufo - reduce fold (zr)'})
  vim.keymap.set('n', 'zm', M.more_folding,    {desc='ufo - fold more (zm)'})
  vim.keymap.set('n', 'zp', M.peek_folded_lines, {desc='ufo - peek and preview folded lines'})
end


-- Resourcing support
if ... == nil then
  M.setup_ufo()
end

M.setup()

return M
