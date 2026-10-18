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

  -- Unless the program within the terminal (e.g. fzf, htop, or nvim recursively)
  -- enables mouse events, a left mouse click on the terminal window would leave terminal mode and
  -- enter the terminal-normal mode. (see :h terminal-input).
  -- Workaround: Swallow left clicks on the text area of the current terminal window only.
  -- Clicks elsewhere (other windows, statusline, separators) would work as usual.
  -- Caveat: mouse-aware programs no longer receive left clicks inside neovim terminals.
  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    pattern = '*',
    callback = function(args)
      vim.keymap.set('t', '<LeftMouse>', function()
        local pos = vim.fn.getmousepos()
        local on_curwin_text = pos.winid == vim.api.nvim_get_current_win() and pos.line > 0
        return on_curwin_text and '' or '<LeftMouse>'
      end, { buffer = args.buf, silent = true, expr = true, remap = false })
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
