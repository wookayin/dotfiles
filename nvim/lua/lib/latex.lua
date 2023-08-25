-- lib.latex
-- LaTeX language support

local M = {}

---@return TSNode?
local function get_node_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_range = { cursor[1] - 1, cursor[2] - 1 } -- note the new '-1' here
  local buf = vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "latex")
  if not ok or not parser then
    return nil
  end
  local root_tree = parser:parse()[1]
  local root = root_tree and root_tree:root()

  if not root then
    return nil
  end

  return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
end

---Returns true if the cursor is currently located in a mathzone, implemented by treesitter.
---Ref: https://github.com/nvim-treesitter/nvim-treesitter/issues/1184
---@return boolean
function M.in_mathzone()
  local node = get_node_at_cursor()
  while node do
    if node:type() == 'text_mode' then
      return false
    elseif vim.tbl_contains({ 'displayed_equation', 'inline_formula', 'math_environment' }, node:type()) then
      return true
    end
    node = node:parent()
  end
  return false
end

return M
