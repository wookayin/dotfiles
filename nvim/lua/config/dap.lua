-- https://github.com/mfussenegger/nvim-dap#usage
-- @see :help dap-configuration

local M = {}

local if_nil = function(value, val_nil, val_non_nil)
  if value == nil then return val_nil
  else return val_non_nil end
end

------------------------------------------------------------------------------
-- DAP Configs.
------------------------------------------------------------------------------
---@diagnostic disable: missing-fields

M.setup_sign = function()
  -- UI: signs
  -- {DapBreakpoint, DapBreakpointCondition, DapBreakpointRejected, DapLogPoint, DapStopped}
  vim.fn.sign_define("DapBreakpoint",          { text = "🔴", texthl = "DapBreakpoint" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "DapBreakpointCondition" })
  vim.fn.sign_define("DapBreakpointRejected",  { text = "⭕", texthl = "DapBreakpointRejected" })
  vim.fn.sign_define("DapStopped", {
    text = "▶",
    texthl = "DapBreakpoint",
    linehl = "DapCurrentLine",
    numhl = "DiagnosticSignWarn",
  })

  require("utils.rc_utils").RegisterHighlights(function()
    vim.cmd [[
      hi DapBreakpoint   guifg=#e03131  ctermfg=Red
      hi DapCurrentLine  guibg=#304577
      hi def link DapBreakpointCondition DapBreakpoint
      hi def link DapBreakpointRejected  DapBreakpoint
    ]]
  end)
end

--- Setup nvim-dap-ui
M.setup_ui = function()
  local dap = require('dap')
  local dapui = require('dapui')

  local columns = function(x) return x end
  local width_ratio = function(x) return x end
  local height_ratio = function(x) return x end

  -- :help nvim-dap-ui
  -- https://github.com/rcarriga/nvim-dap-ui#configuration
  -- ~/.vim/plugged/nvim-dap-ui/lua/dapui/config/init.lua

  require("dapui").setup {
    mappings = {
      -- Use a table to apply multiple mappings
      expand = { "<CR>", "<2-LeftMouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    element_mappings = {
      stacks = {
        open = {"<CR>", "o"},
      }
    },
    layouts = {
      {
        position = "left",
        size = columns(30),
        elements = {
          { id = "scopes", size = height_ratio(0.1) },
          { id = "breakpoints", size = height_ratio(0.2) },
          { id = "stacks", size = height_ratio(0.3) },
          { id = "watches", size = height_ratio(0.4) },
        },
      },
      { elements = { "repl" }, size = height_ratio(0.25), position = "bottom" },
      { elements = { "console", }, size = width_ratio(0.25), position = "right" },
    },
    controls = {
      -- Enable control buttons
      enabled = vim.fn.exists("+winbar") > 0,
      elements = "repl",  -- show in this element
    },
    floating = {
      max_height = nil, -- These can be integers or a float between 0 and 1.
      max_width = nil, -- Floats will be treated as percentage of your screen.
      border = "single", -- Border style. Can be "single", "double" or "rounded"
      mappings = {
        close = { "q", "<Esc>" },
      },
    },
    windows = { indent = 1 },
    render = {
      max_type_length = nil, -- Can be integer or nil.
      max_value_lines = 100, -- Can be integer or nil.
    }
  }

  -- Register custom dapui elements (dapui v3.0+)
  local dapui_exception = {
    buffer = require("dapui.util").create_buffer("DAP Exceptions", { filetype = "dapui_exceptions" }),
    float_defaults = function() return { enter = false } end
  }
  function dapui_exception.render()
    -- get the diagnostic information and draw upon rendering/entering.
    local session = require("dap").session()
    if session == nil then
      return
    end
    local buf = dapui_exception.buffer()
    local diagnostics = vim.diagnostic.get(nil, { namespace = session.ns } )  ---@type Diagnostic[]
    local msg = table.concat(vim.tbl_map(function(d) return d.message end, diagnostics), '\n')
    if not msg or msg == "" then
      msg = "(No exception was caught)"
    end
    pcall(function()
      vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(msg, '\n'))
      vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    end)
  end
  xpcall(function()
    dapui.register_element("exception", dapui_exception)
  end, function(err)
    if err:match("already exists") then return end
    vim.notify(debug.traceback(err, 1), vim.log.levels.ERROR, { title = "dapui" })
  end)

  -- Custom highlights for dap-ui elements
  vim.cmd [[
    hi DapReplPrompt guifg=#fab005 gui=NONE
    augroup dapui_highlights
      autocmd!
      autocmd FileType dap-repl syntax match DapReplPrompt '^dap>'
    augroup END
  ]]

  -- Completion in DAP widgets, via nvim-cmp
  require("cmp").setup {
    enabled = function()
      return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
        or require("cmp_dap").is_dap_buffer()
    end
  }
  require("cmp").setup.filetype({
    "dap-repl", "dapui_watches", "dapui_hover", "dapui_eval_input"
  }, {
    sources = {
      { name = "dap", trigger_characters = { '.' } },
    },
  })

  -- Events
  -- https://microsoft.github.io/debug-adapter-protocol/specification#Events
  -- e.g., initialized, stopped, continued, exited, terminated, thread, output, breakpoint, module, etc.
  dap.listeners.after.event_initialized["dapui_config"] = function()
    -- Open DAP UI Elements when a debug session starts, unless openUIOnEntry is false.
    ---@diagnostic disable-next-line: undefined-field
    local openUIOnEntry = if_nil(dap.session().config.openUIOnEntry, true, false)
    if openUIOnEntry then
      dapui.open {}
    end
  end
  dap.listeners.after.event_stopped["dapui_config"] = function()
    -- Open DapUI when the debugger hits a breakpoint.
    dapui.open {}
  end

  -- autocmds for dapui elements
  do
    vim.cmd [[
      augroup dapui
        autocmd!
        autocmd WinEnter * if &filetype == 'dap-repl'    | startinsert! | endif
        autocmd WinEnter * if &filetype == 'dap-watches' | startinsert! | endif
      augroup END
    ]]
  end

  -- DAP REPL: insert mode keymaps need to be fixed (C-j, C-k, C-l, etc.)
  local dapui_keymaps = vim.api.nvim_create_augroup("dapui_keymaps", { clear = true })
  vim.api.nvim_create_autocmd("WinEnter", {
    pattern = "*",
    group = dapui_keymaps,
    desc = 'Fix scrolloff for dap-repl',
    callback = function()
      if vim.bo.filetype == 'dap-repl' then
        vim.wo.scrolloff = 0  -- to allow 'clear' REPL
      end
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "dap-repl",
    group = dapui_keymaps,
    desc = 'Fix and add insert-mode keymaps for dap-repl',
    callback = function()
      -- TODO ctrl-x
      vim.keymap.set('i', '<c-h>', '<C-g>u<C-w>h', { buffer = true, desc = 'Move to the left window' })
      vim.keymap.set('i', '<c-j>', '<C-g>u<C-w>j', { buffer = true, desc = 'Move to the above window' })
      vim.keymap.set('i', '<c-k>', '<C-g>u<C-w>k', { buffer = true, desc = 'Move to the below window' })
      vim.keymap.set('i', '<c-l>', '<c-u><c-\\><c-o>zt', { buffer = true, remap = true, desc = 'Clear REPL' })
      vim.keymap.set('i', '<c-p>', '<Up>',   { buffer = true, remap = true, desc = 'Previous Command' })
      vim.keymap.set('i', '<c-n>', '<Down>', { buffer = true, remap = true, desc = 'Next Command' })

      -- Override <Tab> so that it can trigger autocompletion even if the cursor does not have a preceding word.
      vim.keymap.set('i', '<tab>', function() require('cmp').complete() end, { buffer = true, desc = 'Tab Completion in dap-repl' })

      -- Debugger commands (see setup_cmds_and_keymaps)
      M._bind_keymaps_for_repl()
    end,
  })

end


function M.start(opts)
  -- Currently, there is no public API to override filetype (see mfussenegger/nvim-dap#1090)<
  -- so we re-implement "select_config_and_run" and call dap.run() manually
  local filetype = opts.filetype or vim.bo.filetype

  local configurations = require('dap').configurations[filetype] or {}
  if #configurations == 0 then
    vim.notify(('No DAP configuration for filetype `%s`.'):format(filetype),
      vim.log.levels.WARN, { title = 'config/dap' })
    return
  end
  require('dap.ui').pick_if_many(
    configurations,
    ("Choose Configuration [%s]"):format(filetype),
    function(configuration)
      return configuration.name
    end,
    function(configuration)
      if configuration then
        require('dap').run(configuration, {})
      end
    end)
end


local function command(cmd, fn, opts)
  opts = vim.tbl_deep_extend('force', { bar = true }, opts or {})
  vim.api.nvim_create_user_command(cmd, fn, opts or {})
end
local function keymap(lhs, rhs)
  if type(rhs) == 'table' then
    if rhs.cmd then rhs = string.format('<cmd>%s<CR>', rhs.cmd)
    else return error("Unknown rhs options.") end
  end
  vim.keymap.set('n', lhs, rhs, { remap = false, silent = true })
end

M.setup_cmds_and_keymaps = function()  -- Commands and Keymaps.
  -- Define "global" commands and keymaps
  -- Define similar keymaps as https://code.visualstudio.com/docs/editor/debugging#_debug-actions
  -- @see :help dap-api  :help dap-mappings
  local dap = require('dap')
  local dapui = require('dapui')

  command('Debug', function()
    if dap.configurations[vim.bo.filetype] then
      vim.cmd [[ DebugStart ]]
    else  -- no available DAP adapters, fall back to build
      vim.cmd [[
        echohl WarningMsg
        echon ":Debug not defined for this filetype. Try :Build instead."
        echohl NONE
      ]]
    end
  end, { desc = 'Start or continue DAP.' })

  command('DebugStart', function(e)
    M.start { filetype = e.fargs[1] }
  end, { nargs = '?', complete = function(...) return vim.tbl_keys(dap.configurations) end })

  command('DebugContinue', 'DapContinue')

  command('DebugTerminate', 'DapTerminate')
  command('DebugStop', 'DapTerminate')
  keymap('<S-F5>',    { cmd = 'DebugClose' })

  command('DebugOpen', function() dapui.open {} end)
  command('DebugClose', function() dapui.close {} end)
  command('DebugToggle', function() dapui.toggle {} end)

  command('DebugBreakpoint', 'DapToggleBreakpoint')  -- see setup_breakpoint_persistence
  command('ToggleBreakpoint', 'DebugBreakpoint')
  command('BreakpointToggle', 'DebugBreakpoint')

  keymap('<leader>b', { cmd = 'DebugBreakpoint' })
  keymap('<F9>',      { cmd = 'DebugBreakpoint' })
  vim.keymap.set('i', '<F9>',  '<c-\\><c-o><Cmd>DebugBreakpoint<CR>')

  command('DebugStackUp','DapStackUp')
  command('DapStackUp', dap.up)
  command('DebugStackDown','DapStackDown')
  command('DapStackDown', dap.down)

  command('DebugStepOver', 'DapStepOver')
  command('DebugStepInto', 'DapStepInto')
  command('DebugStepOut', 'DapStepOut')
  keymap('<F10>',     { cmd = 'DapStepOver' })
  keymap('<F11>',     { cmd = 'DapStepInto' })
  keymap('<S-F11>',   { cmd = 'DapStepOut' })

  command('DapRunToCursor',   function() dap.run_to_cursor() end)
  command('DebugRunToCursor', function() dap.run_to_cursor() end)
  keymap('<C-F10>',   { cmd = 'DapRunToCursor' })

  -- Keymaps for dap-repl (insert mode), on FileType
  M._bind_keymaps_for_repl = function()
    vim.keymap.set('i', '<F5>', '<cmd>DebugContinue<CR>', { buffer = true })
    vim.keymap.set('i', '<M-F5>', '<cmd>DebugContinue<CR>', { buffer = true })
    vim.keymap.set('i', '<S-F5>', '<cmd>DebugClose<CR>', { buffer = true })
    vim.keymap.set('i', '<F9>', '<noop>', { buffer = true })
    vim.keymap.set('i', '<F10>', '<cmd>DapStepOver<CR>', { buffer = true })
    vim.keymap.set('i', '<F11>', '<cmd>DapStepInto<CR>', { buffer = true })
    vim.keymap.set('i', '<S-F11>', '<cmd>DapStepOut<CR>', { buffer = true })
    vim.keymap.set('i', '<C-F10>', '<cmd>DapRunToCursor<CR>', { buffer = true })
  end

  -- see M._bind_session_keymaps() for session-only key mappings
end

M.setup_session_keymaps = function()
  -- Debug-Session-Only keymaps.
  -- Keymaps that are temporarily active ONLY during the debug session.
  -- When the DAP session terminates, keymaps will be reset.

  local dap = require('dap')

  M._keymaps_original = {}
  local get_keymap = function(mode, lhs)
    local keymaps = vim.api.nvim_get_keymap(mode)
    for _, keymap in pairs(keymaps) do
      if keymap.lhs == lhs then return keymap end
    end
    return nil
  end
  local debug_nmap = function(lhs, rhs, opts)
    M._keymaps_original[lhs] = get_keymap('n', lhs)
    opts = vim.tbl_deep_extend('keep', opts or {}, { bar = true })
    vim.keymap.set('n', lhs, rhs, { noremap = true, nowait = true })
  end
  local to_bool = function(x)
    if x == nil then return false end
    if type(x) == "boolean" then return x end
    if type(x) == "number" then return x > 0 end
    if type(x) == "string" then return x ~= "" end
    error("Unknown type : " .. type(x))
  end

  -- Override "global" keymaps when DAP session initiailzes.
  dap.listeners.after.event_initialized["dap_keymaps"] = function() M._bind_session_keymaps() end
  M._bind_session_keymaps = function()
    debug_nmap('<F5>', '<cmd>DebugContinue<CR>')
    debug_nmap('<S-F5>', '<Cmd>DapTerminate<CR>')

    debug_nmap('<leader>c', '<cmd>DebugContinue<CR>')  -- Continue
    debug_nmap('<leader>n', '<cmd>DebugStepOver<CR>')  -- Next
    debug_nmap('<leader>s', '<cmd>DebugStepInto<CR>')  --  Step
    debug_nmap('<leader>t', '<cmd>DebugRunToCursor<CR>')  -- run To cursor
    debug_nmap('<leader>f', '<cmd>DebugStepOut<CR>')  -- Finish
    debug_nmap('<leader>r', '<cmd>DebugStepOut<CR>')  -- Return

    debug_nmap('K', function() require("dapui").eval(nil, {}) end,
        { desc = 'Evaluate or examine the expression on the cursor.'})
    debug_nmap('?', function() M.DebugEval() end,
        { desc = 'Evaluate an arbitrary expression using input dialog.'})

    debug_nmap('<C-u>', '<cmd>DebugStackUp<CR>')
    debug_nmap('<C-d>', '<cmd>DebugStackDown<CR>')

    debug_nmap('<leader>e', function()
      require("dapui").float_element("exception", { enter = false })
    end, { desc = 'Show the active exception in a floating window.' })
  end

  -- Restore the keymap existing to before the DAP session
  -- Some adapters may not fully support the 'terminated' event, see mfussenegger/nvim-dap#742
  dap.listeners.after.disconnect["dap_keymaps"] = function() M.unbind_session_keymaps() end
  dap.listeners.after.event_terminated["dap_keymaps"] = function() M.unbind_session_keymaps() end
  M.unbind_session_keymaps = function()
    for _, keymap in pairs(M._keymaps_original) do
      if keymap then
        vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs or keymap.callback,
          {  -- see :map-arguments
            silent = to_bool(keymap.silent),
            expr = to_bool(keymap.expr),
            nowait = to_bool(keymap.nowait),
            noremap = to_bool(keymap.noremap),
            replace_keycodes = to_bool(keymap.replace_keycodes),
            script = to_bool(keymap.script),
          })
      else
        vim.keymap.del(keymap.mode, keymap.lhs)
      end
    end
    M._keymaps_original = {}
  end

end

------------------------------------------------------------------------------
-- Not essential, but useful advanced setups
------------------------------------------------------------------------------

M.setup_virtualtext = function()
  -- https://github.com/theHamsta/nvim-dap-virtual-text
  require("nvim-dap-virtual-text").setup {
    enabled = true,

    virt_text_pos = 'eol',  ---@type 'inline'|'eol'

    --- A callback that determines how a variable is displayed or whether it should be omitted
    --- @param variable Variable https://microsoft.github.io/debug-adapter-protocol/specification#Types_Variable
    --- @param buf integer
    --- @param stackframe dap.StackFrame https://microsoft.github.io/debug-adapter-protocol/specification#Types_StackFrame
    --- @param node userdata tree-sitter node identified as variable definition of reference (see `:h tsnode`)
    --- @param options nvim_dap_virtual_text_options Current options for nvim-dap-virtual-text
    --- @return string|nil A text how the virtual text should be displayed or nil, if this variable shouldn't be displayed
    display_callback = function(variable, buf, stackframe, node, options)
      if options.virt_text_pos == 'inline' then
        return ' = ' .. variable.value
      else
        return '  ◄ ' .. variable.name .. ' = ' .. variable.value
      end
    end,
  }

  require("utils.rc_utils").RegisterHighlights(function()
    vim.cmd [[
      highlight! NvimDapVirtualText          guifg=#898989 gui=italic
      highlight! NvimDapVirtualTextChanged   guifg=#e8590c gui=italic
    ]]
  end)
end

M.setup_breakpoint_persistence = function()
  -- https://github.com/Weissle/persistent-breakpoints.nvim

  require('persistent-breakpoints').setup {
    load_breakpoints_event = { "BufReadPost" }
  }

  local pb_api = require('persistent-breakpoints.api')

  -- Ensure called at least once after VimEnter, because DAP is loading lazily
  pb_api.load_breakpoints()

  -- Override and keymaps
  command("DebugBreakpoint", function() pb_api.toggle_breakpoint() end)
end


M.DebugEval = function(default_expr)
  -- :DebugEval command ('?' in the session keymap)

  if require('dap').session() == nil then
    return vim.notify('DebugEval: Not in a Debug session.', vim.log.levels.WARN, {title = 'nvim-dap'})
  end
  if default_expr == "" then default_expr = nil end

  -- Get user input and evaluate the expression.
  local opts = {
    prompt = "DebugEval> ",
    default = default_expr or vim.fn.expand('<cexpr>'),
    -- Assumes dressing.nvim; see lua module "dressing.input"
    -- completion does not support lua funcref yet.
    -- This works as an omnicomplete, so needs cmp-omni.
    completion = "custom,v:lua.require('config.dap').DebugEvalCompletion",
    insert_only = false,
  }
  vim.ui.input(opts, function(input)
    if input and input ~= "" then
      -- Show evaluation of the input expression in a floating window.
      vim.defer_fn(function()
        require "dapui".eval(input, {})
      end, 10)
    end
  end)
end

M.DebugEvalCompletion = function(A, L, P)
  -- Hack: Monkey-batch buffer vars and keymaps upon the first completion hit (<Tab>)
  local cmp = require('cmp')
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(bufnr, "filetype", "dapui_eval_input")  -- to make is_dap_buffer() return true
  cmp.setup.buffer({ enabled = true })
  vim.keymap.set("i", "<Tab>", function()
    if cmp.visible() then cmp.select_next_item()
    else cmp.complete() end
  end, { buffer = bufnr })
  vim.keymap.set("i", "<S-Tab>", function()
    if cmp.visible() then cmp.select_prev_item() end
  end, { buffer = bufnr })
  cmp.complete()
  return ''
end

-- Customize REPL commands
M.setup_repl_handlers = function()
  local repl = require("dap.repl")
  local utils = require("dap.utils")
  local commands = {}

  commands.eval_and_print = function(text)
    local session = assert(require("dap").session())
    session:evaluate(text, function(err, resp)
      local message = nil
      if err then message = utils.fmt_error(err)
      else message = resp.result
      end

      if message then
        repl.append(message, nil, { newline = false })
      end
    end)
  end

  repl.commands.custom_commands[".p"] = commands.eval_and_print
  repl.commands.custom_commands["p"] = commands.eval_and_print
end


------------------------------------------------------------------------------
-- Adapters & Language Configs
-- @see :help dap-configuration
------------------------------------------------------------------------------

---@param fn fun(yield: fun(ret))  A callback function to be wrapped in a coroutine.
---            The wrapped function takes a argument `yield`, which a result is passed to.
local function wrap_coroutine(fn)
  return function()
    return coroutine.create(function(dap_co)
      local yield = function(ret)
        coroutine.resume(dap_co, ret)
      end
      xpcall(function()
        fn(yield)
      end,
      function(err) -- catch exceptions
        local msg = debug.traceback(err, 2)
        vim.notify(msg, vim.log.levels.ERROR, { title = "config.dap" })
      end)
    end)
  end
end

--- Lua adapter(osv): https://github.com/jbyuki/one-small-step-for-vimkind
---
--- Our use case of lua debugging is limited to the following scenario:
--- 1. On a UI-attached neovim instance (say "S") that is going to be debugged,
---    launch a OSV lua debug server (localhost:8086) through:
---    > :LuaDebugServerLaunch [8086]
--- 2. then open another neovim instance (say "C") that will run a DAP session as the
---    debugger client, by attaching to the OSV debugging server running on "S":
---    > :DebugStart lua
M.setup_lua = function()
  local dap = require('dap')

  command('LuaDebugServerLaunch', function(e)
    local port = tonumber(e.fargs[1] or 8086)
    local server = require("osv").launch { port = port }
    if not server then
      return error("Lua OSV server has failed to launch.")
    end
    vim.notify(("Lua OSV server launched on port %s.\n" ..
                "Run `:DebugStart lua` in another vim."):format(server.port))
  end, { nargs = '?' })

  dap.configurations.lua = {
    {
      type = 'nlua',
      request = 'attach',
      name = "Attach to an remote Neovim instance",
      host = "127.0.0.1",
      port = wrap_coroutine(function(yield)
        vim.ui.input({
          prompt = "Lua OSV server port (:LuaDebugServerLaunch) [8086]:",
          default = '8086', relative = 'editor'
        }, function(input)
          if not input or input == "" then return end
          local port = tonumber(input)
          if not port then
            return vim.schedule_wrap(vim.api.nvim_err_writeln)("Invalid port number: " .. input)
          end
          yield(port)
        end)
      end),
    },
  }
  ---@param configuration table<string, any>
  dap.adapters['nlua'] = function(callback, configuration)
    callback({
      type = 'server',
      host = configuration.host or "127.0.0.1",
      port = configuration.port or 8086,
    })
  end
end

--- python dap: https://github.com/mfussenegger/nvim-dap-python
M.setup_python = function()
  require('dap-python').setup()
  require('dap-python').test_runner = 'pytest'

  -- Let python breakpoint() hit DAP's breakpoint
  vim.env.PYTHONBREAKPOINT = 'debugpy.breakpoint'

  -- Customize launch configuration (:help dap-python.DebugpyLaunchConfig)
  -- https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings
  ---@diagnostic disable-next-line: undefined-field
  local configurations = require('dap').configurations.python
  for _, configuration in pairs(configurations) do
    ---@cast configuration table<string, any>
    -- makes third party libraries and packages debuggable
    configuration.justMyCode = false
    -- stop at first line of user code for better interaction.
    configuration.stopOnEntry = true
    -- dap-adapter-python does not support multiprocess yet (it often leads to deadlock)
    -- let's work around the bug by disabling multiprocess patch in debugpy.
    -- see microsoft/debugpy#1096, mfussenegger/nvim-dap-python#21
    configuration.subProcess = false
    -- Always use the current cwd of editor/buffer, not the file's absolute path
    configuration.cwd = function()
      return vim.fn.getcwd()
    end
  end

  -- Unit test integration: see neotest config (config/testing)
end


-- Entrypoint.
M.setup = function()
  -- Essentials
  M.setup_sign()
  M.setup_ui()
  M.setup_cmds_and_keymaps()
  M.setup_session_keymaps()

  -- Extensions
  M.setup_virtualtext()
  M.setup_breakpoint_persistence()
  M.setup_repl_handlers()

  -- Adapters
  M.setup_lua()
  M.setup_python()
end


-- Resourcing support
if ... == nil then
  M.setup()
end

return M
