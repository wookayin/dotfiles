-- config/ui.lua
-- Configs for UI-related plugins.

local M = {}

-- Experimental: ui2 (a.k.a. extui)
-- highlight cmdline, messages in a real buffer.
-- See :help ui2 ($VIMRUNTIME/doc/lua.txt)
-- NOTE: Use 'g<' to see more messages!
function M.setup_extui()
  if vim.fn.has('nvim-0.12') == 0 then
    return false
  end

  vim.schedule(function()
    require('vim._core.ui2').enable {
      enable = true,
      msg = {
        -- 'cmd': similar to the classic pager, in the bottom (defaults)
        -- 'msg': floating window message, to the 'msg window'
        target = 'cmd',
        --- Different msg routing per message type (see :help ui-messages)
        ---@type table<string, 'cmd'|'msg'|'pager'>
        targets = {
          verbose = 'msg',
        },
      },
    }
  end)

  -- Customization for 'cmdline', 'msgmore', 'msgbox', 'msgprompt', 'pager' buffers/windows
  local augroup_extui = vim.api.nvim_create_augroup('extui_custom', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'pager',
    group = augroup_extui,
    callback = function(args)
      -- <Esc>, <C-c>: Close the pager window
      vim.keymap.set('n', '<C-c>', '<cmd>close<CR>', { buffer = true, remap = false })
      vim.keymap.set('n', '<Esc>', '<cmd>close<CR>', { buffer = true, remap = false, nowait = true })
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

function M.setup_input()
  -- https://github.com/r0nsha/multinput.nvim#configuration
  -- $VIMPLUG/multinput.nvim/lua/multinput/config.lua
  ---@diagnostic disable-next-line: missing-fields
  require('multinput').setup {
    opts = {
      numbers = 'multiline',
    },
    completion = true,
    win = {
      title = 'Input: ',
      border = 'rounded',
      relative = 'cursor',
      col = -1,
    },
  }

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'multinput',
    callback = function(ev)
      -- <C-c> cancels without confirming
      vim.keymap.set('i', '<C-c>', '<Esc>q', { buffer = ev.buf, remap = true })
    end,
  })
end

function M.setup_snacks()
  -- https://github.com/folke/snacks.nvim?tab=readme-ov-file#-usage
  require('snacks').setup {
    --- $VIMPLUG/snacks.nvim/docs/input.md
    input = {
      -- Do NOT use as vim.ui.input()
      enabled = false,
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
    --- $VIMPLUG/snacks.nvim/docs/terminal.md
    terminal = {
      win = {
        bo = {
          buflisted = true,
        }
      },
    },
    --- $VIMPLUG/snacks.nvim/docs/image.md
    image = {
      enabled = true,
      doc = {
        enabled = true,
        -- Do not render math and images inline for now -- but use floating
        -- window preview. While inline images are really great, it's a bit
        -- aggressive as we don't have a full control of display layout on many
        -- small icon-ish images which can look quite messy on some documents.
        -- Also, for now there is no good way to toggle or configure the
        -- behavior per buffer or per filetype.
        -- See also https://github.com/folke/snacks.nvim/issues/1739
        inline = false,
        float = true,
      },
      math = {
        enabled = true,
      },
    }
  }

  -- Turn off animations (for zen mode and everything else), it's annoying
  vim.g.snacks_animate = false
  require("utils.rc_utils").RegisterHighlights(function()
    vim.api.nvim_set_hl(0, 'SnacksDim', {
      fg = 'NONE',
      dim = vim.fn.has('nvim-0.12.0') > 0 and true or nil,
    })
  end)

  --- misc setup for Snacks
  -- :bd[elete] => :BDelete (but preserves the window layout)
  -- :bdelete => raw built-in :bdelete, just in case we need it
  local H = {}
  vim.fn.CommandAlias('bd', 'BDelete')
  vim.fn.CommandAlias('bdel', 'BDelete')
  vim.api.nvim_create_user_command('BDelete', function(opts)
    local buf = H.parse_buf(opts)
    Snacks.bufdelete { buf = buf, force = opts.bang }
  end, {
    desc = ':bdelete, but preserves window layout',
    nargs = '?', bang = true,
  })
  -- :bw[ipeout] => :BWipeout
  vim.fn.CommandAlias('bw', 'BWipeout')
  vim.api.nvim_create_user_command('BWipeout', function(opts)
    local buf = H.parse_buf(opts)
    Snacks.bufdelete { buf = buf, force = opts.bang, wipe = true }
  end, {
    desc = ':bwipeout, but preserves window layout',
    nargs = '?', bang = true,
  })
  H.parse_buf = function(opts)
    if vim.trim(opts.args) == '' then return 0
    elseif tonumber(opts.args) == nil then
      return error("Invalid argument")
    else return tonumber(opts.args)
    end
  end
end

-- Resourcing support
if ... == nil then
  M.setup_extui()
  M.setup_notify()
  M.setup_input()
  -- M.setup_snacks()  -- does not support setup() again
end

return M
