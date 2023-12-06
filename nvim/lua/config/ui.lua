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
  ---@diagnostic disable-next-line: missing-fields
  require('notify').setup({
    stages = "slide",
    on_open = function(win)
      vim.api.nvim_win_set_config(win, { focusable = false })
      vim.api.nvim_win_set_option(win, "winblend", vim.g.nvim_notify_winblend)
    end,
    level = (function()
      local is_debug = #(os.getenv("DEBUG") or "") > 0 and os.getenv("DEBUG") ~= "0";
      if is_debug then
        vim.schedule(function() vim.notify("vim.notify threshold = DEBUG", vim.log.levels.DEBUG, { title = 'nvim-notify' }) end)
        return vim.log.levels.DEBUG
      else return vim.log.levels.INFO
      end
    end)(),
    timeout = 3000,
    fps = 60,
    background_colour = "#000000",
  })

  --- @class config.ui.notify.Config: notify.Config
  --- @field print? boolean If true, also do :echomsg (so that msg can be saved in :messages)
  --- @field echom? boolean Alias to print
  --- @field markdown? boolean If true, highlight the message window in markdown with treesitter.
  ---
  --- vim.notify with additional extensions on opts
  --- @param opts config.ui.notify.Config?
  vim.notify = function(msg, level, opts)
    opts = opts or {}
    if opts.print or opts.echom then
      local hlgroup = ({
        [vim.log.levels.WARN] = 'WarningMsg', ['warn'] = 'WarningMsg',
        [vim.log.levels.ERROR] = 'Error', ['error'] = 'Error',
      })[level] or 'Normal'
      vim.api.nvim_echo({{ msg, hlgroup }}, true, {})
    end

    if opts.markdown then
      local markdown_on_open = vim.schedule_wrap(function(win)
        local buf = vim.api.nvim_win_get_buf(win)
        vim.wo[win].conceallevel = 2  -- do not show literally ```, etc.
        pcall(vim.treesitter.start, buf, 'markdown')
      end)
      opts.on_open = (function(on_open)
        return function(win)
          if on_open ~= nil then on_open(win) end
          markdown_on_open(win)
        end
      end)(opts.on_open)
    end

    return require("notify")(msg, level, opts)
  end
end

function M.setup_dressing()
  -- Prettier vim.ui.select() and vim.ui.input()
  -- https://github.com/stevearc/dressing.nvim#configuration
  -- default config: $VIMPLUG/dressing.nvim/lua/dressing/config.lua
  require('dressing').setup {

    input = {
      -- the greater of 140 columns or 90% of the width
      prefer_width = 80,
      max_width = { 140, 0.9 },

      border = 'double',

      -- Allow per-instance dynamic option. See stevearc/dressing.nvim#71
      -- merge the current input config with the runtime dynamic opts
      get_config = function(opts)
        local current_opts = require("dressing.config").input
        return vim.tbl_deep_extend("force", current_opts, opts or {})
      end,
    },

    select = {
      -- Note: fzf_lua backend is buggy, does not trigger on_choice upon abort()
      backend = { "telescope", "builtin" },

      -- Allow per-instance dynamic option. See stevearc/dressing.nvim#71
      -- merge the current input config with the runtime dynamic opts
      get_config = function(opts)
        local current_opts = require("dressing.config").input
        return vim.tbl_deep_extend("force", current_opts, opts or {})
      end,
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
