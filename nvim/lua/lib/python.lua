-- lib/python
-- Utilities and functions specific to python

local M = {}


--[[ Implementations for $DOTVIM/after/ftplugin/python.lua ]]

M.toggle_breakpoint = function()
  local pattern = "breakpoint()"  -- Use python >= 3.7.
  local line = vim.fn.getline(".") --[[@as string]]
  line = vim.trim(line)
  local lnum = vim.fn.line(".")  ---@cast lnum integer

  if vim.startswith(line, pattern) then
    vim.cmd.normal([["_dd]])  -- delete the line without altering registers
  else
    local indents = string.rep(" ", vim.fn.indent(vim.fn.prevnonblank(lnum)) or 0)
    vim.fn.append(lnum - 1, indents .. pattern)
    vim.cmd.normal("k")
  end
  -- save file without any events
  if vim.bo.modifiable and vim.bo.modified then
    vim.cmd [[ silent! noautocmd write ]]
  end
end

M.toggle_fstring = function()
  -- Credit: https://www.reddit.com/r/neovim/comments/tge2ty/python_toggle_fstring_using_treesitter/
  local winnr = 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  ---@type TSNode?
  local node = require("utils.ts_utils").get_node_at_cursor(winnr)

  while (node ~= nil) and (node:type() ~= "string") do
    node = node:parent()
  end
  if node == nil then
    vim.api.nvim_echo({{ "f-string: not in a string node.", "WarningMsg" }}, false, {})
    return
  end

  ---@diagnostic disable-next-line: unused-local
  local srow, scol, erow, ecol = require("utils.ts_utils").get_vim_range({ node:range() })
  vim.fn.setcursorcharpos(srow, scol)

  local char = vim.api.nvim_get_current_line():sub(scol, scol)
  local is_fstring = (char == "f")

  if is_fstring then
    vim.cmd [[normal "_x]]
    -- if cursor is in the same line as text change
    if srow == cursor[1] then
      cursor[2] = cursor[2] - 1 -- negative offset to cursor
    end
  else
    vim.cmd [[noautocmd normal if]]
    -- if cursor is in the same line as text change
    if srow == cursor[1] then
      cursor[2] = cursor[2] + 1 -- positive offset to cursor
    end
  end
  vim.api.nvim_win_set_cursor(winnr, cursor)
end

M.toggle_line_comment = function(text)
  local comment = '# ' .. text
  local line = vim.fn.getline('.') --[[ @as string ]]
  local newline  ---@type string

  if vim.endswith(line, comment) then
    -- Already exists at the end: strip the comment
    newline = string.match(line:sub(1, #line - #comment), "(.-)%s*$")
  else
    newline = line .. '  ' .. comment
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  vim.fn.setline('.', newline)
end

M.toggle_typing = function(name)
  if vim.fn.has('nvim-0.9') == 0 then
    return vim.api.nvim_err_writeln("toggle_typing: this feature requires neovim 0.9.0.")
  end

  local winnr = 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)  -- (row,col): (1,0)-indexed
  local bufnr = vim.api.nvim_get_current_buf()

  local function has_type(node, t) return node and node:type() == t end
  local function get_text(node) return vim.treesitter.get_node_text(node, bufnr) end

  ---@type TSNode?
  local node = vim.treesitter.get_node()

  -- Climb up and find the closest ancestor node whose children has a `type` node:
  while (node ~= nil) and not vim.tbl_contains({
    'assignment', 'typed_default_parameter', 'typed_parameter', 'function_definition',
  }, node:type()) do
    node = node:parent()
  end
  -- Find its direct children of type `type`
  ---@type TSNode?
  local type_node = node and vim.tbl_filter(function(n)
    return n:type() == 'type'
  end, node:named_children())[1] or nil
  if not type_node then
    vim.cmd.echon(([["toggle_typing[%s]: not in a type hint node."]]):format(name))
    return
  end
  -- Check range

  local unpack_generic = function(node)
    -- Determine if `node` represents `Optional[...]` (w.r.t `name`), for example.
    --  type: (type)
    --    (generic_type)
    --      (identifier)
    --      (type_parameter)
    --        (type) <-- returns this node `T` if given `Optional[T]`.
    assert(node:type() == 'type')
    node = node:named_child(0)
    if has_type(node, 'generic_type') then
      node = node:named_child(0)
      if (has_type(node, 'identifier') and get_text(node) == name) then
        ---@cast node TSNode
        node = node:next_named_sibling() -- 0.9.0 only
      end
      if has_type(node, 'type_parameter') then
        node = assert(node):named_child(0)
        if has_type(node, 'type') then
          return node
        end
      end
    end
    return nil
  end

  local T_node = unpack_generic(type_node)  ---@type TSNode?
  local new_text  ---@type string
  if T_node then
    -- replace: e.g., Optional[T] => T
    new_text = get_text(T_node, bufnr)
  else
    -- replace: e.g., T => Optional[T]
    new_text = name .. "[" .. get_text(type_node, bufnr) .. "]"
  end

  -- treesitter range is 0-indexed and end-exclusive
  -- nvim_buf_set_text() also uses 0-indexed and end-exclusive indexing
  local srow, scol, erow, ecol = type_node:range()
  vim.api.nvim_buf_set_text(0, srow, scol, erow, ecol, { new_text })

  -- Restore cursor
  vim.api.nvim_win_set_cursor(winnr, cursor)
end

return M
