-- path.utils
-- see also: $VIMPLUG/nvim-lspconfig/lua/lspconfig/util.lua

local M = {}

function M.join(...)
  return vim.fn.resolve(table.concat({...}, '/'))
end

---@param marker_patterns string[]
---@param opts table? { buf = ... } or { path = ... } or <buf> or <path>
---@return string|nil
function M.find_project_root(marker_patterns, opts)
  local start_path
  if opts == nil or type(opts.buf) == "number" then
    local buf = opts and opts.buf or 0
    start_path = vim.fs.dirname(vim.api.nvim_buf_get_name(buf))
  elseif type(opts) == "table" and opts.path then
    start_path = opts.path
  elseif type(opts) == "string" then
    start_path = opts
  else
    error("Unknown type: " .. vim.inspect(opts))
  end

  local marker = vim.fs.find(
    marker_patterns,
    {
      upward = true, stop = vim.loop.os_homedir(), limit = 1,
      path = vim.fn.fnamemodify(start_path, ":p"),
    })[1]

  -- fnamemodify: don't use :p, it addes trailing slashes when matched .git
  return marker and vim.fn.fnamemodify(marker, ":h") or nil
end

return M
