local M = {}

function M.Defer(args, delay)
  if delay == nil or delay < 0 then
    delay = 0
  end

  local _schedule = function()
    vim.defer_fn(function()
      vim.api.nvim_command(args)
    end, delay)
  end

  if vim.fn.has('vim_starting') > 0 then
    vim.api.nvim_create_autocmd('UIEnter', {
      pattern = '*',
      callback = _schedule,
      once = true,
    })
  else
    _schedule()
  end
end

-- Defer: Execute a command, but execute with defer_fn().
-- {count}Defer: Defer execution to {count} milliseconds later, e.g. 100Defer: 100 ms
do
  vim.api.nvim_create_user_command('Defer', function(opts)
    M.Defer(opts.args, opts.count)
  end,
  { nargs = '+', desc = 'Defer an command.', count = true })
end

return M
