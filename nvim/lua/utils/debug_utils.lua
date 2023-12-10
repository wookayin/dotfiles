-- vim(utils): Helper functions for debugging neovim & lua.
local M = {}

-- Use a separate nvim-notify instance with the log level "DEBUG"
-- (other than global vim.notify instance)
---@diagnostic disable: missing-fields
M.notify = require("notify").instance({ level = "DEBUG" })
---@diagnostic enable: missing-fields

-- Inspect a lua object and display through vim.notify and :Message.
function M.inspect(obj, opts)
  local repr = vim.inspect(obj)
  opts = vim.tbl_deep_extend("force", opts or {}, {
    title = vim.split(debug.traceback(), '\n')[3],
    timeout = 10000,
  })
  M.notify(repr, vim.log.levels.DEBUG, opts)
  return repr
end

function M.notify_traceback()
  -- Strip this stack frame itself
  M.notify(vim.trim(debug.traceback("", 2)),
    vim.log.levels.DEBUG, { title = 'DEBUG (traceback)' })
end

function M.show_logs()
  local original_history = require("notify").history
  require("notify").history = M.notify.history
  pcall(function()
    vim.cmd [[ Telescope notify ]]
  end)
  require("notify").history = original_history
end

return M
