-- lib/python
-- Utilities and functions specific to python

local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

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
  local node = ts_utils.get_node_at_cursor()  ---@type TSNode?

  while (node ~= nil) and (node:type() ~= "string") do
    node = node:parent()
  end
  if node == nil then
    vim.api.nvim_echo({{ "f-string: not in a string node.", "WarningMsg" }}, false, {})
    return
  end

  ---@diagnostic disable-next-line: unused-local
  local srow, scol, erow, ecol = ts_utils.get_vim_range({ node:range() })
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

return M
