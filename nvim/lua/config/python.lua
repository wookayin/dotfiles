local M = {}

M.setup_pyrepl = function()
  local pyrepl = require("pyrepl")

  --- @see pyrepl.ConfigOpts
  pyrepl.setup({
    image_provider = "image",  -- image.nvim
  })

  -- :pyrepl, :Pyrepl [open|close|hide]
  vim.fn.CommandAlias('pyrepl', 'Pyrepl')
  vim.api.nvim_create_user_command('Pyrepl', function(opts)
    local subcmd = opts.args  ---@type string?
    if (subcmd or '') == '' or subcmd == 'open' then pyrepl.open_repl()
    elseif subcmd == 'close' then pyrepl.close_repl();
    elseif subcmd == 'hide' then pyrepl.hide_repl();
    else
      vim.notify('Unknown subcommand: ' .. subcmd, vim.log.levels.ERROR)
    end
  end, {
    desc = ':Pyrepl (:REPL)',
    complete = function() return { 'open', 'close', 'hide' } end,
    nargs = '?',
  })

  -- Commands Keymaps (<leader>j for "jupyter"), buffer-local
  local augroup = vim.api.nvim_create_augroup('config.python.pyrepl', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'python',
    callback = function()
      local _opts = function(o)
        return vim.tbl_extend('force', { buffer = true, remap = false }, o)
      end

      -- main commands
      vim.keymap.set('n', '<leader>jo', pyrepl.open_repl, _opts { desc = 'pyrepl: open REPL' })
      vim.keymap.set('n', '<leader>jq', pyrepl.hide_repl, _opts { desc = 'pyrepl: hide REPL' })
      vim.keymap.set('n', '<leader>jQ', pyrepl.close_repl, _opts { desc = 'pyrepl: close REPL' })
      vim.keymap.set('n', '<leader>jH', pyrepl.open_image_history, _opts { desc = 'pyrepl: image history' })

      -- send commands
      vim.keymap.set('n', '<leader>jB', pyrepl.send_buffer, _opts { desc = 'pyrepl: send buffer' })
      vim.keymap.set('n', '<leader>jj', pyrepl.send_cell, _opts { desc = 'pyrepl: send cell' })
      vim.keymap.set('v', '<leader>jj', pyrepl.send_visual, _opts { desc = 'pyrepl: send selection' })
      -- also <Shift-Enter>
      vim.keymap.set('i', '<S-CR>', pyrepl.send_cell, _opts { desc = 'pyrepl: send cell' })
      vim.keymap.set('n', '<S-CR>', pyrepl.send_cell, _opts { desc = 'pyrepl: send cell' })
      vim.keymap.set('v', '<S-CR>', pyrepl.send_visual, _opts { desc = 'pyrepl: send selection' })

      -- cell navigation
      vim.keymap.set('n', '[j', pyrepl.step_cell_backward, _opts { desc = 'pyrepl: jump to prev cell' })
      vim.keymap.set('n', ']j', pyrepl.step_cell_forward, _opts { desc = 'pyrepl: jump to next cell' })
    end,
  })
end

-- Resourcing support
if ... == nil then
  M.setup_pyrepl()
end

return M
