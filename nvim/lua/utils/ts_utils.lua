-- utils.ts_utils
-- Treesitter Utilities used throughout neovim config

local M = {}

--- Get the treesitter node (the most ancestor) that contains
--- the current cursor location in the range.
---
--- The difference to `nvim-treesitter.ts_utils.get_node_at_cursor()`:
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
--- 2. The return value is never nil. When parser is not available, it will raise errors.
---
---    Use vim.F.npcall() to make error-safe!
---
--- @param winnr? integer window number, 0 (the current window) by default
--- @param ignore_injected_langs? boolean
--- @return TSNode
function M.get_node_at_cursor(winnr, ignore_injected_langs)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)  -- line: 1-indexed, col: 0-indexed
  local insert_offset = ((winnr == 0 or winnr == vim.api.nvim_get_current_win()) and vim.fn.mode() == 'i') and 1 or 0

  -- Treesitter range: row, col are both 0-indexed
  local cursor_range = { cursor[1] - 1, cursor[2] - insert_offset }
  local buf = vim.api.nvim_win_get_buf(winnr)

  local root_lang_tree = vim.treesitter.get_parser(buf) ---@type LanguageTree
  local root ---@type TSNode|nil
  if ignore_injected_langs then
    for _, tree in pairs(root_lang_tree:trees()) do
      local tree_root = tree:root()
      if tree_root and vim.treesitter.is_in_node_range(tree_root, cursor_range[1], cursor_range[2]) then
        root = tree_root
        break
      end
    end
  else
    root = require("nvim-treesitter.ts_utils").get_root_for_position(cursor_range[1], cursor_range[2], root_lang_tree)
  end

  assert(root)
  local node = root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
  return assert(node)
end

return M
