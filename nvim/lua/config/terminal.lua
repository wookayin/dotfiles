--- Additional settings to make terminal buffers and windows work better in NVIM.
local M = {}

--- Automatically enter terminal (insert) mode when entering neovim terminal buffers.
function M.setup_autoinsert()
  local augroup = vim.api.nvim_create_augroup('terminal_autoinsert', { clear = true })

  -- There is a bug (or just a strange behavior?) of neovim where buffer options
  -- (e.g. &buftype) gets updated too late on WinEnter autocmds: when a new window is opened,
  -- the new buffer being opened in the new window executes the autocmd body *after* the autocmd.
  -- The actual buffer would not yet have been loaded at the time when the autocmd WinEnter event
  -- is being executed. As a result, the new window will enter the insert mode even if it is not
  -- having a terminal buffer.
  -- One known solution is to check if <amatch> is empty.
  -- Credit: https://vi.stackexchange.com/questions/15966/strange-behaviour-of-autocmd
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufWinEnter' }, {
    group = augroup,
    pattern = '*',
    callback = function(args)
      -- <amatch>. Lua's args.match does not raise even if &verbose > 0
      if args.match ~= '' and vim.bo.buftype == 'terminal' then
        vim.cmd.startinsert()
      end
    end,
  })
  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    pattern = '*',
    callback = function(args)
      if vim.startswith(vim.api.nvim_buf_get_name(args.buf), 'term://') then
        vim.cmd.startinsert()
      end
    end,
  })

  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    pattern = '*',
    callback = function(args)
      -- Mouse click puts into normal mode even in the terminal mode;
      -- Disable this behavior: neovim should keep in the terminal-insert mode.
      vim.keymap.set('t', '<LeftMouse>', '<Cmd>startinsert<CR>', { buffer = args.buf, silent = true })
    end,
  })
end

function M.setup()
  M.setup_autoinsert()
end

-- Resourcing support
if ... == nil then
  M.setup()
end

return M
