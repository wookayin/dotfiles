-- config/ui.lua
-- Configs for UI-related plugins.

local M = {}

-- Experimental: ui2 (a.k.a. extui)
-- highlight cmdline, messages in a real buffer.
-- See https://github.com/neovim/neovim/pull/27811 and :help ui2 ($VIMRUNTIME/doc/lua.txt)
-- NOTE: Use 'g<' to see more messages!
function M.setup_extui()
  if vim.fn.has('nvim-0.12') == 0 then
    return false
  end

  vim.schedule(function()
    require('vim._core.ui2').enable {
      enable = true,
      msg = {
        target = 'cmd', -- for now I'm happy with 'cmd'; 'box' seems buggy
      },
    }
  end)

  -- Customization for 'cmdline', 'msgmore', 'msgbox', 'msgprompt', 'pager' buffers/windows
  local augroup_extui = vim.api.nvim_create_augroup('extui_custom', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'pager',
    group = augroup_extui,
    callback = function(args)
      vim.keymap.set('n', '<C-c>', '<cmd>close<CR>', { buffer = true, remap = false })
    end,
  })
end

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
      vim.wo[win].winblend = vim.g.nvim_notify_winblend
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
  --- @field lang? string If given, highlight the message window in the given lang with treesitter.
  ---
  --- vim.notify with additional extensions on opts
  --- @param msg string Content of the notification to show to the user.
  --- @param level integer|nil One of the values from |vim.log.levels|.
  --- @param opts config.ui.notify.Config?
  vim.notify = function(msg, level, opts)
    vim.validate('msg', msg, 'string')
    vim.validate('level', level, {'number', 'string'}, true)  -- allows string for convenience
    vim.validate('opts', opts, 'table', true)  -- opts can be optional

    opts = opts or {}
    if opts.print or opts.echom then
      local hlgroup = ({
        [vim.log.levels.WARN] = 'WarningMsg', ['warn'] = 'WarningMsg',
        [vim.log.levels.ERROR] = 'Error', ['error'] = 'Error',
      })[level] or 'Normal'
      vim.api.nvim_echo({{ msg, hlgroup }}, true, {})
    end

    if opts.markdown then
      opts.lang = 'markdown'
    end
    if opts.lang then
      local treesitter_on_open = vim.schedule_wrap(function(win)
        local buf = vim.api.nvim_win_get_buf(win)
        vim.wo[win].conceallevel = 2  -- do not show literally ```, etc.
        pcall(vim.treesitter.start, buf, opts.lang)
      end)
      opts.on_open = (function(on_open)
        return function(win)
          if on_open ~= nil then on_open(win) end
          treesitter_on_open(win)
        end
      end)(opts.on_open)
    end

    return require("notify")(msg, level, opts)
  end

  require("config.telescope").on_ready(function()
    require("telescope").load_extension("notify")
    vim.cmd [[ command! -nargs=0 Notifications  :Telescope notify ]]
  end)
end

function M.setup_snacks()
  -- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-usage
  require('snacks').setup {
    --- $VIMPLUG/snacks.nvim/docs/input.md
    input = {
      -- Use as vim.ui.input()
      enabled = true,
    },
    --- $VIMPLUG/snacks.nvim/docs/styles.md
    styles = {
      input = {
        keys = {
          i_ctrl_c = { "<C-c>", "cancel", mode = { "i", "n" } },
        },
      },
    },
    --- $VIMPLUG/snacks.nvim/docs/picker.md
    picker = {
      -- Use as vim.ui.select()
      ui_select = true,
    },
    --- $VIMPLUG/snacks.nvim/docs/image.md
    image = {
      enabled = true,
    }
  }
end

-- Resourcing support
if ... == nil then
  M.setup_notify()
  -- M.setup_snacks()  -- does not support setup() again
  M.init_quickui()
  M.setup_quickui()
end

return M
