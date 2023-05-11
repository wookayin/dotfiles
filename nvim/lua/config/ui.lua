-- config/ui.lua
-- Configs for UI-related plugins.

local M = {}

function M.setup_notify()
  vim.cmd [[
    command! -nargs=0 NotificationsPrint   :lua require('notify')._print_history()
    command! -nargs=0 PrintNotifications   :NotificationsPrint
  ]]
  vim.g.nvim_notify_winblend = 20

  -- :help notify.setup()
  -- :help notify.config
  require('notify').setup({
    stages = "slide",
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { focusable = false })
      vim.api.nvim_win_set_option(win, "winblend", vim.g.nvim_notify_winblend)
    end,
    timeout = 3000,
    fps = 60,
    background_colour = "#000000",
  })

  vim.notify = require("notify")
end

function M.setup_dressing()
  -- Prettier vim.ui.select() and vim.ui.input()
  -- https://github.com/stevearc/dressing.nvim#configuration
  require('dressing').setup {

    input = {
      -- the greater of 140 columns or 90% of the width
      prefer_width = 80,
      max_width = { 140, 0.9 },
    },

    select = {
    },

  }
end


-- Resourcing support
if vim.v.vim_did_enter > 0 then
  M.setup_notify()
  M.setup_dressing()
end

return M
