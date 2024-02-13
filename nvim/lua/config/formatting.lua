local M = {}

--- Configure conform.nvim formatters
function M.setup_conform()

  _G.conform = require("conform")
  require("conform").setup {
    formatters_by_ft = {}, -- see below
    format_on_save = function(buf)
      ---@return table format_args
      return M._should_format_on_save(buf)
    end,
  }

  -- Configure filetypes and formatters
  -- Do not configure if LSP provides a good formatting (e.g., rustfmt)
  local formatter_opts = require("conform").formatters
  local one_of = vim.tbl_flatten
  local cf = {}  ---@type table<string, conform.FiletypeFormatter>

  cf.lua = (function()
    formatter_opts["stylua"] = {
      prepend_args = {
        "--indent-type", "Spaces",
        "--indent-width", tostring(2),
        "--respect-ignores", -- requires stylua 0.19+
      },
      -- Make sure cwd is always the project root so that .styluaignore is respected
      cwd = require("conform.util").root_file {
        ".styluaignore", ".stylua.toml", ".git",
      },
    }
    return { "stylua" }
  end)()
  cf.python = (function()
    -- Make sure cwd is always the project root to the file, so that
    -- the right config file (pyproject.toml, .style.yapf, etc.) is picked up
    local py_root = require("conform.util").root_file({
      "setup.py", "pyproject.toml", ".style.yapf", ".git",
    })
    formatter_opts["yapf"] = { cwd = py_root }
    formatter_opts["isort"] = { cwd = py_root }
    return { "isort", "yapf" }
  end)()
  cf.sh = (function()
    formatter_opts["shfmt"] = {
      prepend_args = function(self, ctx)
        if ctx == nil then ctx = self end -- compat for < v5.0
        return { "--indent", tostring(vim.bo[ctx.buf].shiftwidth)
      } end,
    }
    return { "shfmt" }
  end)()
  cf.bash = cf.sh
  cf.zsh = cf.sh
  cf.javascript = { one_of({ "prettierd", "prettier" }) }
  cf.typescript = { one_of({ "prettierd", "prettier" }) }

  for ft, v in pairs(cf) do
    require("conform").formatters_by_ft[ft] = v
  end

  M._setup_command()
  M._setup_formatexpr()
end


local make_range = function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      ["start"] = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  return range
end
local error_format_command = function(lsp_fallback, range, filetype)
  local msg = string.format(
    "No %s formatters are available %s filetype `%s`.\n" ..
    "Try %s to see more information.",
    lsp_fallback and "conform or LSP" or "conform",
    range and "for range formatting on" or "for", filetype,
    lsp_fallback and "`:ConformInfo` or `:LspInfo`" or "`:ConformInfo`")
  vim.notify(msg, vim.log.levels.WARN, { title = "config.formatting" })
end

-- Define :Format and :ConformFormat commands.
function M._setup_command()
  local Format = function(args, lsp_fallback)
    local range = make_range(args)
    local ret = require("conform").format({
      bufnr = 0,
      lsp_fallback = lsp_fallback,
      range = range,
      formatters = #args.fargs > 0 and args.fargs or nil,
    })
    if not ret then
      error_format_command(lsp_fallback, range, vim.bo.filetype)
    end
  end

  local complete = function()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.tbl_map(function(formatter)
      return formatter.name
    end, require("conform").list_formatters(bufnr))
  end

  vim.api.nvim_create_user_command("Format",
    function(args) return Format(args, true) end, {
    nargs = "*", range = true, complete = complete,
    desc = "format the current buffer using conform and LSP.",
  })
  vim.api.nvim_create_user_command("ConformFormat",
    function(args) return Format(args, false) end, {
    nargs = "*", range = true, complete = complete,
    desc = "format the current buffer using conform only (no LSP fallback).",
  })
end

--- Can be used in ftplugins to create buffer commands for formatting
---@param name string command name
---@param formatters string|string[] the names of formatters to use.
function M.create_buf_command(name, formatters)
  formatters = vim.tbl_flatten { formatters }
  vim.api.nvim_buf_create_user_command(0, name, function(args)
    local range = make_range(args)
    local ret = require("conform").format {
      bufnr = 0,
      lsp_fallback = false,
      range = range,
      formatters = formatters,
    }
    if not ret then
      error_format_command(false, range, vim.bo.filetype)
    end
  end, {
    range = true,
    desc = "format the current buffer using conform, formatters = " .. vim.inspect(formatters),
  })
end


function M._setup_formatexpr()
  -- formatexpr (must be buffer-local for specfic filetypes).
  -- so that `gq` can work (see stevearc/conform.nvim#55)
  -- and automatic formatting during the insert mode can happen
  vim.api.nvim_create_autocmd('FileType', {
    pattern = vim.tbl_keys(require("conform").formatters_by_ft),
    group = vim.api.nvim_create_augroup('conform_formatexpr', { clear = true }),
    callback = function()
      vim.opt_local.formatexpr = "v:lua.conform_formatexpr()"
    end,
  })
  _G.conform_formatexpr = function()
    local allow_internal = vim.tbl_contains({ "i", "R", "ic", "ix" }, vim.fn.mode())
    local ret = require("conform").formatexpr({ lsp_fallback = true })
    if allow_internal then
      return ret -- insert mode (e.g. exceeding textwidth), allow fallback to the built-in
    else
      return 0 -- never fallback to the built-in formatexpr (see stevearc/conform.nvim#55)
    end
  end
end


--- Configure per-project (workspace) autoformatting.
--- This can be turned on and off by `:AutoFormat` command or `enable_autoformat()`.
--- Ftplugins can call `maybe_autostart_autoformatting()` to auto-start autoformatting
--- for the project. See $DOTVIM/after/ftplugin/python.lua for an example.

---@class formatting.WorkspaceStatus
---@field enabled boolean whether to autoformat in this workspace.
---@field filetypes string[]|nil run format-on-save on these filetypes only.
---@field format_opts table|nil options to conform.format()

---@type table<string, formatting.WorkspaceStatus> path -> per-workspace autoformat status
M._workspace_status = {}
M._workspace_autostart_checked = {}

local find_project_root = function(buf)
  if vim.bo[buf].buftype ~= "" then  -- only for normal file buffer
    return false
  end

  -- Determine project root. Relies on vim.b.project_root set in ftplugins
  ---@diagnostic disable-next-line: redundant-return-value  Note: false positive of neodev
  local path = vim.api.nvim_buf_call(buf, function() return vim.fn.expand("%:p") end)
  local project_root = (
    vim.b[buf].project_root or
    require("utils.path_utils").find_project_root({ ".git" }, { path = path }))

  project_root = project_root and vim.fn.resolve(project_root) or nil
  return project_root
end

function M._should_format_on_save(buf)
  local project_root = find_project_root(buf)
  if not project_root then
    return false  -- Do not autoformat if a project/workspace can't be detected
  end

  -- some common blacklists
  if project_root:match '/lib/python3.%d+/' then
    return false
  end

  local workspace_status = M._workspace_status[project_root]
  if not workspace_status or not workspace_status.enabled then
    return false
  end

  if (workspace_status.filetypes ~= nil and
      not vim.tbl_contains(workspace_status.filetypes, vim.bo[buf].filetype)) then
    return false
  end

  -- Do autoformatting.
  -- should return arguments (table) to conform.format()
  local format_opts = workspace_status.format_opts or {}
  return vim.tbl_deep_extend("keep", format_opts, { lsp_fallback = true })
end

---@param buf? integer
---@param arg? 'on'|'off'|'toggle'|'status'|true|false
---@param opts? { ['reason']: string?, ['format_opts']: table? }
function M.enable_autoformat(buf, arg, opts)
  buf = buf or 0
  if buf == 0 then buf = vim.api.nvim_get_current_buf() end
  opts = opts or {}

  local project_root = find_project_root(buf)
  if not project_root then
    local msg = ("Cannot autoformat for buffer %d, project root unknown or disabled."):format(buf)
    vim.api.nvim_echo({{ msg, "WarningMsg" }}, true, {})
    return
  end

  local function echo_status()
    local is_enabled = (M._workspace_status[project_root] or {}).enabled and true or false
    vim.api.nvim_echo({
      { project_root, "Directory" },
      { ": ", "Normal" },
      { is_enabled and "AutoFormat enabled" or "AutoFormat disabled",
        is_enabled and "MoreMsg" or "Normal" },
    }, true, {})
  end

  -- Autoformat files with the "same filetype" only, in the same workspace
  local filetype = vim.bo[buf].filetype

  if arg == nil or arg == 'on' or arg == 'enable' or arg == true then
    M._workspace_status[project_root] = {
      enabled = true,
      filetypes = { filetype }, -- TODO merge with existing filetypes?
      format_opts = opts.format_opts,
    }
  elseif arg == 'off' or arg == 'disable' or arg == false then
    (M._workspace_status[project_root] or {}).enabled = false
  elseif arg == 'toggle' then
    (M._workspace_status[project_root] or {}).enabled = not (M._workspace_status[project_root] or {}).enabled
  elseif arg == 'status' then -- TODO refactor as is_enabled
    echo_status()
  else
    error("Invalid args: " .. arg)
  end

  if arg ~= 'status' then
    local msg = ("%s auto-formatting for the project:\n`%s`"):format(
      (M._workspace_status[project_root] or {}).enabled and "Enabled" or "Disabled", project_root)
    local timeout = 1000
    if opts.reason then
      msg = msg .. "\n\nreason:\n" .. opts.reason .. ""
      timeout = 5000
    end
    if opts.format_opts then
      msg = msg .. "\n\nformat options: " .. vim.inspect(opts.format_opts) .. ""
    end
    vim.notify(msg, vim.log.levels.INFO, { title = ":AutoFormat", timeout = timeout, markdown = true })
    echo_status()
  end
end

function M.setup_autoformatting()
  vim.api.nvim_create_user_command('AutoFormat', function(e)
    if e.args == "" then e.args = 'toggle' end
    M.enable_autoformat(0, e.args)
  end, {
    nargs = '?',
    complete = function() return { 'on', 'off', 'toggle', 'status' } end,
  })
end

--- Enable autoformatting if a condition is met (checked asynchronously).
---@param buf? integer
---@param condition fun(project_root: string):boolean|string[],string?
---         Determine whether to autoformat. Returns:
---         - enable: boolean, or list of formatters to run (implies enabled)
---         - reason: any optional message for describing the reason to enable autoformatting
function M.maybe_autostart_autoformatting(buf, condition)
  -- turn on auto formatting ONLY ONCE per the same 'project' directory,
  -- if the project is configured to use autoformatting (pyproject.toml, .style.yapf, etc.)
  buf = buf or 0
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end

  local project_root = find_project_root(buf)
  if not project_root then
    return false
  end
  if M._workspace_autostart_checked[project_root] then
    return true
  end
  M._workspace_autostart_checked[project_root] = true

  -- Check asynchronously because condition() often involves file I/O.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return  -- avoid race condition
    end
    local enable, reason = condition(project_root)
    if enable == true then
      M.enable_autoformat(buf, true, { reason = reason })
    elseif type(enable) == 'table' then
      M.enable_autoformat(buf, true, {
        reason = reason,
        format_opts = { formatters = enable },
      })
    end
  end)
end


function M.setup()
  M.setup_conform()
  M.setup_autoformatting()
end

if ... == nil then
  M.setup()
end

return M
