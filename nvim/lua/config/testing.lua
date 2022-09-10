-- see :help neotest
-- see ~/.vim/plugged/neotest/lua/neotest/config/init.lua

-- neovim 0.7.0 or higher is required.

if not pcall(require, 'neotest') then
  print("Warning: neotest not available, skipping config.")
  return
end

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
}

-- Add command shortcuts and keymappings
-- see ~/.vim/after/ftplugin/python.vim as well


vim.cmd [[
  command! -nargs=0 NeotestRun      lua require("neotest").run.run()
  command! -nargs=0 NeotestRunFile  lua require("neotest").run.run(vim.fn.expand("%"))
  command! -nargs=0 Neotest         NeotestRun
  command! -nargs=0 Test            NeotestRun

  command! -nargs=0 NeotestStop     lua require("neotest").run.stop()
  command! -nargs=0 NeotestOutput   lua require("neotest").output.open()
  command! -nargs=0 NeotestOutputSplit  lua require("neotest").output.open({ open_win = function() vim.cmd "botright 20split" end })
  command! -nargs=0 NeotestSummary  lua require("neotest").summary.toggle()
  command! -nargs=0 TestOutput      lua require("neotest").output.open()
  call CommandAlias('TO', 'TestOutput')
]]

vim.cmd [[
  noremap <leader>tr  :NeotestRun<CR>
  noremap <leader>tR  :NeotestRunFile<CR>
  noremap <leader>to  :NeotestOutput<CR>
]]

-- See ~/.vim/after/ftplugin/python.vim for filetype-specfic mapping to neotest commands
