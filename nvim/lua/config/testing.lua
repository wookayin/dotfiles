-- see :help neotest
-- see ~/.vim/plugged/neotest/lua/neotest/config/init.lua

-- neovim 0.7.0 or higher is required.

if not pcall(require, 'neotest') then
  print("Warning: neotest not available, skipping config.")
  return
end

local M = {}
M.custom_consumers = {}

-- :help neotest.config
-- @see ~/.vim/plugged/neotest/lua/neotest/config/init.lua
function M.setup_neotest()
  require("neotest").setup {
    adapters = {
      require("neotest-python")({
        dap = { justMyCode = false },
        args = { "-vv", "-s" },
        runner = 'pytest',
      }),
      require("neotest-plenary"),
    },
    floating = { -- :help neotest.Config.floating
      max_width = 0.9,
      options = {},
    },
    icons = {
      passed = "✅",
      running = "⌛",
      failed = "❌",
      skipped = "🚫",
    },
    -- custom consumers.
    consumers = {
      attach_or_output = M.custom_consumers.attach_or_output(),
    }
  }
end

-- Add command shortcuts and keymappings
-- see ~/.vim/after/ftplugin/python.vim as well
function M.setup_commands_keymaps()
  vim.cmd [[
    command! -nargs=0 NeotestRun      lua require("neotest").run.run()
    command! -nargs=0 NeotestRunFile  lua require("neotest").run.run(vim.fn.expand("%"))
    command! -nargs=0 Neotest         NeotestRun
    command! -nargs=0 Test            NeotestRun

    command! -nargs=0 NeotestStop             lua require("neotest").run.stop()
    command! -nargs=0 NeotestOutput           lua require("neotest").attach_or_output.open()
    command! -nargs=0 NeotestOutputSplit      lua require("neotest").output.open({ open_win = function() vim.cmd "botright 20split" end })

    command! -nargs=0 NeotestSummary  lua require("neotest").summary.toggle()
    command! -nargs=0 TestOutput      lua require("neotest").output.open()
    call CommandAlias('TO', 'TestOutput')
  ]]

  vim.cmd [[
    noremap <leader>tr  :NeotestRun<CR>
    noremap <leader>tR  :NeotestRunFile<CR>
    noremap <leader>to  :NeotestOutput<CR>
  ]]
end


-- A custom neotest consumer, i.e., neotest.attach_or_run
function M.custom_consumers.attach_or_output()
  local self = { name = "attach_or_output" }
  local neotest = require("neotest")

  ---@type neotest.Client
  local client = nil

  self = setmetatable(self, {
    __call = function(_, client_)
      client = client_
      return self
    end,
  })

  -- neotest.attach_or_run.open()
  function self.open(args)
    args = args or {}
    local pos = neotest.run.get_tree_from_args(args)
    if pos and client:is_running(pos:data().id) then
      neotest.run.attach()
    else
      neotest.output.open()
    end
  end

  return self
end


M.setup_neotest()
M.setup_commands_keymaps()

pcall(function()
  neotest = require('neotest')
  RC.testing = M
end)

-- See ~/.vim/after/ftplugin/python.vim for filetype-specfic mapping to neotest commands
