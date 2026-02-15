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

-- Resourcing support
if ... == nil then
  M.setup()
end

return M
