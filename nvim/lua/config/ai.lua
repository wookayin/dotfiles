local M = {}

function M.setup_claude()
  -- https://github.com/coder/claudecode.nvim
  if vim.fn.executable('claude') == 0 then
    local _notify = function()
      vim.notify_once('Command `claude` not found.', vim.log.levels.ERROR)
    end
    vim.api.nvim_create_user_command('Claude', _notify, {})
    _notify()
    return
  end

  ---@see ClaudeCodeConfig
  ---@diagnostic disable: missing-fields
  require('claudecode').setup {
    auto_start = false,  -- TODO race condition

    terminal = {
      split_side = "right", -- "left" or "right"
      split_width_percentage = 0.36,
    },

    -- After sending some text, move focus to the claude terminal
    focus_after_send = true,

    diff_opts = {
      -- Moves focus back to terminal after diff opens
      keep_terminal_focus = true,
    },

  }
  ---@diagnostic enable: missing-fields

  -- Keymaps: <leader>C as the main prefix for Claude Code
  vim.keymap.set('n', "<leader>CC", "<cmd>Claude <cr>",            { desc = "Toggle Claude" })
  vim.keymap.set('n', "<leader>Cf", "<cmd>Claude focus<cr>",       { desc = "Focus Claude" })
  vim.keymap.set('n', "<leader>Cm", "<cmd>Claude selectmodel<cr>", { desc = "Select Claude model" })
  vim.keymap.set('n', "<leader>Cb", "<cmd>Claude add %<cr>",       { desc = "Add current buffer" })
  vim.keymap.set('v', "<leader>Cs", "<cmd>Claude send<cr>",        { desc = "Send to Claude" })
  vim.keymap.set('n', "<leader>Ca", "<cmd>Claude accept<cr>",      { desc = "Accept diff" })
  vim.keymap.set('n', "<leader>Cd", "<cmd>Claude deny<cr>",        { desc = "Deny diff" })

  -- :Claude <subcommand> [args...] → :ClaudeCode<Subcommand> [args...]
  local subcmds = {
    add = 'Add', send = 'Send', stop = 'Stop', open = 'Open', focus = 'Focus',
    start = 'Start', close = 'Close', status = 'Status',
    deny = 'DiffDeny', accept = 'DiffAccept', diff_deny = 'DiffDeny', diff_accept = 'DiffAccept',
    select_model = 'SelectModel', model = 'SelectModel'
  }

  local claudecode = require('claudecode')
  vim.api.nvim_create_user_command('Claude', function(opts)
    -- auto_start claude server, but only upon first call via :Claude
    if claudecode.state.server == nil then
      local success, _ = require('claudecode').start(false)
      if not success then
        vim.notify('Claude: cannot establish a connection.', vim.log.levels.ERROR)
      end
    end

    local fargs = opts.fargs
    if #fargs == 0 then vim.cmd('ClaudeCode'); return end
    local sub = table.remove(fargs, 1):lower()
    local name = subcmds[sub]

    -- If it was never opened before, 'send' does not work. Open first!
    if name == 'send' then
      vim.cmd 'ClaudeCodeOpen'
    end
    if name then
      local cmd = 'ClaudeCode' .. name
      if opts.range > 0 then
        cmd = opts.line1 .. ',' .. opts.line2 .. cmd
      end
      if #fargs > 0 then cmd = cmd .. ' ' .. table.concat(fargs, ' ') end
      vim.cmd(cmd)
    else
      vim.notify('Claude: unknown subcommand: ' .. sub, vim.log.levels.ERROR)
    end
  end, {
    range = true,
    nargs = '*',
    complete = function(arglead, cmdline, _)
      if #vim.split(cmdline, '%s+', { trimempty = true }) > 2 then return {} end
      local lead = arglead:lower()
      local matches = vim.tbl_filter(
        function(s) return s:sub(1, #lead) == lead end,
        vim.tbl_keys(subcmds)
      )
      table.sort(matches)
      return matches
    end,
  })

  --- Additional keymaps
  -- <F8> for Claude
  vim.keymap.set('n', '<F8>', '<Cmd>Claude<CR>')
  vim.keymap.set('i', '<F8>', '<Cmd>Claude<CR>')
  vim.keymap.set('x', '<F8>', '<Cmd>Claude send<CR>')

  local augroup = vim.api.nvim_create_augroup('config.keymap', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'snacks_terminal',  -- assuming :Claude runs on snacks terminal
    group = augroup,
    callback = function()
      vim.keymap.set('t', '<F8>', '<Cmd>Claude<CR>', { buffer = true })
    end,
  })

end


-- Resourcing support
if ... == nil then
  M.setup_claude()
end

return M
