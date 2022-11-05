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

    command! -nargs=0 NeotestSummary  lua require("neotest").summary.toggle()
    command! -nargs=0 TestOutput      lua require("neotest").output.open()
    call CommandAlias('TO', 'TestOutput')
  ]]

  vim.api.nvim_create_user_command('NeotestOutputSplit', function(opts)
    local height = tonumber(opts.args) or 20
    require("neotest").output.open { open_win = function() vim.cmd(string.format('botright %dsplit', height)) end }
  end, { nargs = '?' })
  vim.api.nvim_create_user_command('NeotestOutputVSplit', function(opts)
    local width = tonumber(opts.args) or 70
    require("neotest").output.open { open_win = function() vim.cmd(string.format('%dvsplit', width)) end }
  end, { nargs = '?' })

  -- keymaps (global)
  vim.cmd [[
    noremap <leader>tr  :NeotestRun<CR>
    noremap <leader>tR  :NeotestRunFile<CR>
    noremap <leader>to  :NeotestOutput<CR>
  ]]

  -- buffer-local keymaps for neotest-output and neotest-attach windows
  local augroup = vim.api.nvim_create_augroup('neotest_widget_keymaps', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'neotest-output', 'neotest-attach' },
    group = augroup,
    callback = function()
      local H = {}
      vim.cmd [[
        " Pressing <F6> again would move the floating window into normal splits
        nnoremap <buffer> <silent> <F6>    <cmd>lua require("config/testing")._move_neotest_floating_to_split()<CR>
        tnoremap <buffer> <silent> <F6>    <cmd>lua require("config/testing")._move_neotest_floating_to_split()<CR>
        " Allow window movement via wincmd hotkeys
        tnoremap <buffer> <silent> <C-w>H  <cmd>wincmd H<CR>
        tnoremap <buffer> <silent> <C-w>J  <cmd>wincmd J<CR>
        tnoremap <buffer> <silent> <C-w>K  <cmd>wincmd K<CR>
        tnoremap <buffer> <silent> <C-w>L  <cmd>wincmd L<CR>
      ]]
    end,
  })
  M._move_neotest_floating_to_split = function()
    if vim.api.nvim_win_get_config(0).relative ~= "" then  -- if floating window?
      vim.cmd [[ wincmd J | resize 25 ]]  -- move to split window to the far bottom
    end
  end

  -- buffer-local keymaps for neotest-summary
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'neotest-summary' },
    group = augroup,
    callback = function()
      vim.cmd [[
        nnoremap <buffer> <silent> <leader>T     <cmd>lua require("neotest").summary.close()<CR>
      ]]
    end
  })

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
-- See ~/.vim/after/ftplugin/python.vim for filetype-specfic mapping to neotest commands

pcall(function()
  neotest = require('neotest')
  RC.testing = M
end)

return M
