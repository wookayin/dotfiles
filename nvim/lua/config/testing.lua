-- see :help neotest
-- see $VIMPLUG/neotest/lua/neotest/config/init.lua

-- neovim 0.7.0 or higher is required.

local M = {}
M.custom_consumers = {}

-- :help neotest.config
-- @see $VIMPLUG/neotest/lua/neotest/config/init.lua
function M.setup_neotest()
  ---@diagnostic disable-next-line: missing-fields
  require("neotest").setup {
    adapters = {
      require("neotest-python")({
        -- see config/lua setup_python()
        dap = {
          justMyCode = false,
          console = "integratedTerminal",
          stopOnEntry = false,  -- which is the default(false)
          subProcess = false,  -- see config/testing.lua
          openUIOnEntry = false,
        },
        args = { "-vv", "-s" },
        runner = 'pytest',
      }),
      require("neotest-plenary").setup {
        min_init = vim.fn.expand("$DOTVIM/init.testing.lua"),
      },
    },
    floating = { -- :help neotest.Config.floating
      max_width = 0.9,
      max_height = 0.8,
      border = "rounded",
      options = {},
    },
    icons = {
      passed = "✅",
      running = "⌛",
      failed = "❌",
      skipped = "🚫",
      unknown = "❔",

      expanded = "┐",
      final_child_prefix = "└",
    },
    quickfix = {
      enabled = true,
      -- do not automatically open quickfix because it can steal focus
      open = false,
    },
    -- custom consumers.
    consumers = {
      ---@diagnostic disable-next-line: assign-type-mismatch
      attach_or_output = M.custom_consumers.attach_or_output(),
    }
  }
end

-- Add command shortcuts and keymappings
-- see $DOTVIM/after/ftplugin/python.vim as well
function M.setup_commands_keymaps()
  vim.cmd [[
    command! -nargs=0 NeotestRun      lua require("neotest").run.run()
    command! -nargs=0 NeotestRunFile  lua require("neotest").run.run(vim.fn.expand("%"))
    command! -nargs=0 Neotest         NeotestRun
    command! -nargs=0 Test            NeotestRun
    command! -nargs=0 TestDebug       lua require("neotest").run.run({ strategy = "dap" })

    command! -nargs=0 NeotestStop             lua require("neotest").run.stop()
    command! -nargs=0 NeotestOutput           lua require("neotest").attach_or_output.open()
    command! -nargs=0 NeotestOutputPanel      lua require("neotest").output_panel.open()

    command! -nargs=0 NeotestSummary  lua require("neotest").summary.toggle()
    command! -nargs=0 TestOutput      lua require("neotest").output.open()
    call CommandAlias('TO', 'TestOutput')
  ]]

  local open_win_split = function(split_or_vsplit, size)
    if split_or_vsplit == 'split' then
      vim.cmd(string.format([[ botright %dsplit ]], size))
    else
      vim.cmd(string.format([[ %dvsplit ]], size))
    end
    local win_id = vim.api.nvim_get_current_win()
    vim.wo[win_id].number = false
    vim.wo[win_id].signcolumn = 'no'
    return win_id
  end

  vim.api.nvim_create_user_command('NeotestOutputSplit', function(opts)
    local height = tonumber(opts.args) or 20
    require("neotest").output.open { open_win = function() return open_win_split('split', height) end }
  end, { nargs = '?' })
  vim.api.nvim_create_user_command('NeotestOutputVSplit', function(opts)
    local width = tonumber(opts.args) or 70
    require("neotest").output.open { open_win = function() return open_win_split('vsplit', width) end }
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
      vim.wo.sidescrolloff = 0

      if vim.bo.filetype == 'neotest-output' then
        vim.cmd [[ norm G ]]  -- scroll to the bottom
      end

      vim.cmd [[
        " Pressing <F6> again would move the floating window into normal splits
        nnoremap <buffer> <silent> <F6>    <cmd>lua require("config.testing")._move_neotest_floating_to_split()<CR>
        tnoremap <buffer> <silent> <F6>    <cmd>lua require("config.testing")._move_neotest_floating_to_split()<CR>
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
        nmap     <buffer> <silent> <F6>          o
      ]]
    end
  })

end


-- A custom neotest consumer, i.e., neotest.attach_or_run
function M.custom_consumers.attach_or_output()
  local self = { name = "attach_or_output" }
  local neotest = require("neotest")
  local async = require("neotest.async")

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
    async.run(function()
      local pos = neotest.run.get_tree_from_args(args)
      if pos and client:is_running(pos:data().id) then
        local is_dap_active = pcall(require, "dap") and require("dap").session() ~= nil or false
        if is_dap_active then
          -- when a DAP session is running with neotest (strategy = dap),
          -- strategy.attach will simply open dap-repl; we would want to show exceptions instead
          -- because dap-terminal (console) will also be displayed
          require("dapui").float_element("exception", { enter = false })
          return
        end
        neotest.run.attach()
      else
        neotest.output.open(args)
      end
    end)
  end

  return self
end


function M.setup()
  M.setup_neotest()
  -- See also $DOTVIM/after/ftplugin/python.vim for filetype-specfic mapping to neotest commands
  M.setup_commands_keymaps()

  _G.neotest = require('neotest')
end

if ... == nil then
  M.setup()
end

return M
