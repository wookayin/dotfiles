-- Config for overseer (task runner)

local M = {}

function M.setup()
  require('overseer').setup {
    task_list = {
      keymaps = {
        -- Dispose task (similar to dd)
        ["<BS>"] = { "keymap.run_action", opts = { action = "dispose" }, desc = "Dispose task" },

        -- Remove default keymaps for CTRL-{j,k} so that these can work as window navigation
        ["<C-k>"] = false,
        ["<C-j>"] = false,
      }
    },
  }

  -- Register handy aliases
  vim.fn.CommandAlias('OS', 'OverseerShell')
  vim.fn.CommandAlias('OT', 'OverseerToggle')
end

--- Additional batteries wrapped around overseer.
function M.setup_extra()
  -- :just, :Just
  vim.cmd [[
    autocmd CmdlineEnter * ++once call CommandAlias('just', 'Just')
  ]]
  vim.api.nvim_create_user_command('Just', function(opts)
    vim.cmd.OverseerShell('just ' .. opts.args)
  end, {
    nargs = '*',
    desc = 'Just (overseer)',
  })
end

-- Resourcing support
if ... == nil then
  M.setup()
  M.setup_extra()
end

return M
