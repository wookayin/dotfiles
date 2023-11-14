-- utils.ts_utils
-- Treesitter Utilities used throughout neovim config

local M = {}


---@return TSNode?
function M.get_node_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_range = { cursor[1] - 1, cursor[2] - 1 } -- note the new '-1' here
  local buf = vim.api.nvim_get_current_buf()
  local parser = vim.F.npcall(vim.treesitter.get_parser, buf)
  if not parser then
    return nil
  end
  local root_tree = parser:parse()[1]
  local root = root_tree and root_tree:root()

  if not root then
    return nil
  end

  return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
end

return M
