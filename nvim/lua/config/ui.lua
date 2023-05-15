-- config/ui.lua
-- Configs for UI-related plugins.

local M = {}

function M.setup_notify()
  vim.cmd [[
    command! -nargs=0 NotificationsPrint   :lua require('notify')._print_history()
    command! -nargs=0 PrintNotifications   :NotificationsPrint
    command! -nargs=0 Messages             :NotificationsPrint
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

function M.init_quickui()
  -- Use unicode-style border (┌─┐) which is more pretty
  vim.g.quickui_border_style = 2

  -- Default preview window size (more lines and width)
  vim.g.quickui_preview_w = 100
  vim.g.quickui_preview_h = 25

  -- Customize color scheme
  vim.g.quickui_color_scheme = 'papercol light'
end

function M.setup_quickui()
  -- Quickui overrides highlight when colorscheme is set (when lazy loaded),
  -- so make sure this callback is executed AFTER plugin init
  -- to correctly override the highlight
  require "utils.rc_utils".RegisterHighlights(function()
    vim.cmd [[
      hi! QuickPreview guibg=#262d2d
    ]]
  end)
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup_notify()
  M.setup_dressing()
  M.init_quickui()
  M.setup_quickui()
end

return M
