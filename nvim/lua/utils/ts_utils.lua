--- utils.ts_utils
--- Additional treesitter utilities used throughout neovim config
-- Note: nvim-treesitter.ts_utils are deprecated; should not depend on it.
-- Note: Use the new vim.treesitter APIs (v0.9.0+) as much as possible.

local M = {}

--- Get the treesitter node (the most ancestor) that contains
--- the current cursor location in the range.
---
--- Differences to `vim.treesitter.get_node()` or `nvim-treesitter.ts_utils.get_node_at_cursor()`:
---
--- 1. This is aware of the "insert mode" to have a better offset on cursor_range. For example:
---
---    1234567 8
---    "foobar|"
---    ^^     ^^
---    ││     ││
---    ││     │└─ string
---    ││     └─ cursor (insert mode)
---    │└─ string_content
---    └─ string
---
---    In the insert mode, the cursor location (1-indexed) will read col = 8, so the
---    original get_node_at_cursor() implementation will return the `string` node at col = 8.
---    But in the insert mode, we would want to get the `string_content` node at col = 7.
---
--- 2. When parser is not available or mis-configured, it will raise errors.
---
---    Use vim.F.npcall() to make error-safe!
---
---
---@param winnr? integer window number, 0 (the current window) by default
---@param ignore_injections? boolean defaults true
---@return TSNode|nil
function M.get_node_at_cursor(winnr, ignore_injections)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)  -- line: 1-indexed, col: 0-indexed
  local insert_offset = ((winnr == 0 or winnr == vim.api.nvim_get_current_win()) and vim.fn.mode() == 'i') and 1 or 0

  -- Treesitter: row, col are both 0-indexed
  local cursor_pos = { cursor[1] - 1, cursor[2] - insert_offset }
  assert(vim.treesitter.get_node, "nvim < 0.9 is unsupported.")

  return vim.treesitter.get_node { pos = cursor_pos, ignore_injections = ignore_injections }
end


---@backport nvim-treesitter.ts_utils.get_root_for_position()
--- (only for compatibility during migration to vim.treesitter APIs, 0.9.0+)
---@deprecated
function M.get_root_for_position(line, col, root_lang_tree)
  local parsers = require "nvim-treesitter.parsers"

  if not root_lang_tree then
    if not parsers.has_parser() then
      return
    end

    root_lang_tree = parsers.get_parser()
  end

  local lang_tree = root_lang_tree:language_for_range { line, col, line, col }

  for _, tree in pairs(lang_tree:trees()) do
    local root = tree:root()

    if root and vim.treesitter.is_in_node_range(root, line, col) then
      return root, tree, lang_tree
    end
  end

  -- This isn't a likely scenario, since the position must belong to a tree somewhere.
  return nil, nil, lang_tree
end


---@backport nvim-treesitter.ts_utils.get_vim_range()
-- Get a compatible vim range (1 index based) from a TS node range.
--
-- TS nodes start with 0 and the end col is ending exclusive.
-- They also treat a EOF/EOL char as a char ending in the first
-- col of the next row.
---@param range integer[]
---@param buf integer|nil
---@return integer, integer, integer, integer
---@deprecated
function M.get_vim_range(range, buf)
  ---@type integer, integer, integer, integer
  local srow, scol, erow, ecol = unpack(range)
  srow = srow + 1
  scol = scol + 1
  erow = erow + 1

  if ecol == 0 then
    -- Use the value of the last col of the previous row instead.
    erow = erow - 1
    if not buf or buf == 0 then
      ecol = vim.fn.col { erow, "$" } - 1
    else
      ecol = #vim.api.nvim_buf_get_lines(buf, erow - 1, erow, false)[1]
    end
    ecol = math.max(ecol, 1)
  end
  return srow, scol, erow, ecol
end


_G.ts_utils = M
return M
