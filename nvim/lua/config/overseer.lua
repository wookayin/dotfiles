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
      },
      render = function(task)
        local render = require("overseer.render")
        return {
          render.join(
            render.status_and_name(task),
            render.duration(task),
            '  '
          )
        }
      end,
    },
    component_aliases = {
      default = {
        "on_exit_set_status",
        -- Make the default notification triggered only upon FAILURE, in favor of statusline
        { "on_complete_notify", statuses = { "FAILURE" } },
        { "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } },
      }
    },
  }

  -- F5, F6, Make, etc.
  -- <F6>   :Output       => Show the overseer task window (or quickfix/terminal, if overriden)
  vim.keymap.set({'n', 'i'}, '<F6>', '<Cmd>Output<CR>', { remap = false })
  vim.api.nvim_create_user_command('Output', function()
    vim.cmd [[ OverseerToggle ]]
    vim.cmd [[ wincmd p ]]  -- let the cursor stay in the working window
  end, {
    nargs = 0,
    desc = 'Output (overseer)',
  })

  -- Register handy aliases
  vim.fn.CommandAlias('R', 'OverseerShell')
  vim.fn.CommandAlias('Run', 'OverseerShell')
  vim.fn.CommandAlias('OS', 'OverseerShell')
  vim.fn.CommandAlias('OT', 'OverseerToggle')
end

--- Lualine integration (see nvim/lua/config/statusline.lua)
--- @return string
function M.statusline()
  local overseer = require('overseer')
  local tasks = overseer.list_tasks()  ---@type overseer.Task[]

  local icons = vim.iter(tasks):filter(function(task) ---@param task overseer.Task
    if task.time_end == nil then return true end
    -- show only active tasks, ended no more than 3 seconds ago
    return task.time_end > os.time() - 3.0
  end):map(function(task) ---@param task overseer.Task
    return ({
      ['PENDING'] = '⏳',
      ['RUNNING'] = '⏳',
      ['SUCCESS'] = '✅',
      ['FAILURE'] = '❌',
      ['CANCELED'] = '⛔';
    })[task.status] or ''
  end):totable()
  return table.concat(icons, ' ')
end

--- Additional batteries wrapped around overseer.
function M.setup_extra()
  local overseer = require("overseer")

  -- :Make command running with overseer
  local function Make(opts)
    local args = vim.fn.expandcmd(opts.args) ---@type string
    -- TODO: sanitize args, avoid shell pipe and injections, etc.
    local cmd
    if vim.o.makeprg == 'make' then
      cmd = vim.trim("make " .. args)
    else
      cmd = vim.fn.expandcmd(vim.o.makeprg)
    end

    local task = overseer.new_task({
      cmd = cmd,
      components = {
        "on_exit_set_status",
        -- Disable "on_complete_notify", we have our custom notification callback
      },
    }) ---@type overseer.Task

    ---@param status overseer.Status
    task:subscribe("on_complete", function(_task, status, result)
      if status ~= "SUCCESS" then
        vim.notify("Build (make) failed! (Try `:OverseerOpen` or `<F6>`)", vim.log.levels.ERROR,
          { title = cmd, markdown = true })
      end
    end)
    task:start()
  end
  vim.api.nvim_create_user_command(
    'Make', Make,
    { nargs = '*', desc = 'Make (overseer)' }
  )

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
