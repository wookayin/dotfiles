local M = {}

-- Set log level to DEBUG when this module is used.
-- Defer execution because notify.setup {} might be called after init
vim.schedule(function()
  ---@diagnostic disable-next-line: missing-fields
  require("notify").setup { level = 'DEBUG' }
end)

-- Inspect a lua object and display through vim.notify and :Message.
function M.inspect(obj, opts)
  local repr = vim.inspect(obj)
  opts = vim.tbl_deep_extend("force", opts or {}, {
    title = vim.split(debug.traceback(), '\n')[3],
    timeout = 10000,
  })
  vim.notify(repr, vim.log.levels.DEBUG, opts)
  return repr
end

function M.notify_traceback()
  -- Strip this stack frame itself
  vim.notify(vim.trim(debug.traceback("", 2)),
    vim.log.levels.DEBUG, { title = 'DEBUG (traceback)' })
end

return M
