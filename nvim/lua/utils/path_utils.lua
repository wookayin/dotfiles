-- path.utils
-- see also: $VIMPLUG/nvim-lspconfig/lua/lspconfig/util.lua

local M = {}

function M.join(...)
  return vim.fn.resolve(table.concat(vim.tbl_flatten {...}, '/'))
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

---Convert a file path to a Lua module name.
---@return string|nil
function M.path_to_lua_package(filePath)
  local function resolve(p)
    return vim.loop.fs_realpath(vim.fn.expand(p) --[[@as string]])
  end

  filePath = resolve(filePath:gsub("\\", "/"))
  if not filePath then
    return nil  -- unknown file?
  end
  local basePaths = {
    -- TODO: Respect the package serach path of actual package loaders.
    resolve("$HOME/.config/nvim") .. "/lua/",
    resolve("$VIMPLUG") .. "/.-/lua/",
  }
  for _, basePath in pairs(basePaths) do
    if filePath:find(basePath) then
      basePath = filePath:match(basePath)
      if basePath then
        local moduleName = filePath:gsub(basePath, ""):gsub("/", "."):gsub("%.lua$", ""):gsub("%.init$", "")
        return moduleName
      end
    end
  end
  return nil
end

---Tests if a file contains certain lua regex patterns.
---@param filePath string
---@param patterns string[]
---@return boolean
---@return nil|{ ['line']:integer, ['match']:string }
function M.file_contains_pattern(filePath, patterns)
  -- Open the file
  local file = io.open(filePath, "r")
  if not file then
    error("Unable to open file: " .. filePath)
  end

  local l = 1
  for line in file:lines() do
    for _, pattern in ipairs(patterns) do
      local match = line:match(pattern)
      if match then
        file:close()
        return true, { line = l, match = match }
      end
    end
    l = l + 1
  end

  file:close()
  return false, nil
end

return M
