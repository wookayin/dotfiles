-- path.utils
-- see also: $VIMPLUG/nvim-lspconfig/lua/lspconfig/util.lua

local M = {}

--- Get the directory of a buffer's file path, or nil if the buffer has no associated file.
--- @param buf integer|nil buffer number, defaults to current buffer
--- @return string|nil
function M.buf_dir(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.validate('buf', buf, 'number', true)

  -- special case: neo-tree, use the explorer's root path directly
  if vim.bo[buf].filetype == 'neo-tree' then
    local neotree_path = require("config.neotree").get_path()
    if neotree_path then
      return neotree_path
    end
  end

  if vim.bo[buf].buftype ~= "" then
    return nil
  end
  local bufname = vim.api.nvim_buf_get_name(buf)
  if bufname == "" then
    return nil
  end
  return vim.fs.dirname(bufname)
end

---@param marker_patterns string[]|nil
---@param start_path string|integer|nil  defaults to cwd. accepts path or bufnr
---@return string|nil
function M.project_root(start_path, marker_patterns)
  marker_patterns = marker_patterns or { '.git' }
  if type(start_path) == 'number' then
    start_path = M.buf_dir(start_path)
  end
  ---@cast start_path string|nil
  if start_path == nil then
    start_path = vim.fn.getcwd()
  end

  local marker = vim.fs.find(
    marker_patterns,
    {
      upward = true, stop = vim.loop.os_homedir(), limit = 1,
      path = vim.fs.abspath(start_path),
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
  local not_nil = function(x) return x ~= nil end

  filePath = resolve(filePath:gsub("\\", "/"))
  if not filePath then
    return nil  -- unknown file?
  end
  local basePaths = vim.tbl_filter(not_nil, {
    -- TODO: Respect the package serach path of actual package loaders.
    resolve("$HOME/.config/nvim") .. "/lua/",
    os.getenv('VIMPLUG') and (resolve("$VIMPLUG") .. "/[%w-]+/lua/"),
  })
  for _, basePath in pairs(basePaths) do
    if filePath:find(basePath) then
      basePath = filePath:match(basePath)
      if basePath then
        local moduleName = filePath:gsub(
          basePath:gsub("%-", "%%-"), ""  -- Note: escape `-` (a magic character)
        ):gsub("/", "."):gsub("%.lua$", ""):gsub("%.init$", "")
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
