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
  -- @see :help dap-api  :help dap-mappings

  keymap('<leader>b', {cmd = 'DapToggleBreakpoint'})
  keymap('<F9>',      {cmd = 'DapToggleBreakpoint'})

  keymap('<F10>',     {cmd = 'DapStepOver'})
  keymap('<F11>',     {cmd = 'DapStepInto'})
  keymap('<S-F11>',   {cmd = 'DapStepOut'})

  command('DebugStart', 'DapContinue')
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

  -- Adapters
  M.setup_python()
end


-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end


(RC or {}).dap = M
return M
