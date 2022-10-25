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

  command('DebugBreakpoint', 'DapToggleBreakpoint')
  command('ToggleBreakpoint', 'DapToggleBreakpoint')
  command('BreakpointToggle', 'DapToggleBreakpoint')

  keymap('<leader>b', { cmd = 'DapToggleBreakpoint' })
  keymap('<F9>',      { cmd = 'DapToggleBreakpoint' })
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
-- Adapters & Language Configs
-- @see :help dap-configuration
------------------------------------------------------------------------------

M.setup_python = function()
  -- python dap: https://github.com/mfussenegger/nvim-dap-python
  require('dap-python').setup()
end


-- Entrypoint.
M.setup = function()
  -- Essentials
  M.setup_sign()
  M.setup_ui()
  M.setup_cmds_and_keymaps()
  M.setup_session_keymaps()

  -- Adapters
  M.setup_python()
end


-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end


(RC or {}).dap = M
return M