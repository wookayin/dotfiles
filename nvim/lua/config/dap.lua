-- https://github.com/mfussenegger/nvim-dap#usage
-- @see :help dap-configuration

local M = {}

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
    "dap-repl", "dapui_watches", "dapui_hover",
  }, {
    sources = {
      { name = "dap", trigger_characters = { '.' } },
    },
  })

  -- Events
  -- https://microsoft.github.io/debug-adapter-protocol/specification#Events
  -- e.g., initialized, stopped, continued, exited, terminated, thread, output, breakpoint, module, etc.
  dap.listeners.after.event_initialized["dapui_config"] = function()
    -- Open DAP UI Elements when a debug session starts;
    dapui.open {}
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

  command('DebugStart', 'DapContinue')
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

    debug_nmap('<C-u>', '<cmd>DebugStackUp<CR>')
    debug_nmap('<C-d>', '<cmd>DebugStackDown<CR>')
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
    --- @param buf number
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


------------------------------------------------------------------------------
-- Adapters & Language Configs
-- @see :help dap-configuration
------------------------------------------------------------------------------

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

  -- Adapters
  M.setup_python()
end


-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end


(RC or {}).dap = M
return M
