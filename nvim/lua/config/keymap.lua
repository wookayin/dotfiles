-- Keymaps (plugin-agnostic)

-- Make timeout delay for key sequence, default is 1000ms
vim.opt.timeoutlen = 500

-- Note: noremap = true (remap = false) by default
local nmap = function(...) vim.keymap.set('n', ...) end
local imap = function(...) vim.keymap.set('i', ...) end
local cmap = function(...) vim.keymap.set('c', ...) end
local xmap = function(...) vim.keymap.set('x', ...) end

-- Insert mode: emacs-like navigation (Ctrl-A, Ctrl-E)
imap('<c-a>', '<c-o>^', { silent = true })  -- beginning-of-line
imap('<c-e>', '<c-o>$', { silent = true })  -- end-of-line

imap('<c-b>', '<c-o>B', { silent = true })  -- words backward
imap('<c-f>', '<c-o>W', { silent = true })  -- words forward


-- In the command mode, <CTRL-/> will toggle the Ex command
-- between `:lua` and `:lua=`, or between `:py` and `:py=`, etc.
cmap('<c-_>', '<c-/>', { remap = true })
cmap('<c-/>', function()
  if vim.fn.getcmdtype() == ':' then
    local line = vim.fn.getcmdline() or ''
    local replace = function(before, new)
      return '<C-b>' .. string.rep('<Del>', #before) .. new .. '<C-e>'
    end
    for _, rule in ipairs {  -- note: order (prefix) matters!
      { 'lua=', 'lua' },
      { 'lua', 'lua=' },
      { 'python3=', 'python3' },
      { 'python3', 'python3=' },
      { 'python=', 'python' },
      { 'python', 'python=' },
      { 'py3=', 'py3' },
      { 'py3', 'py3=' },
      { 'py=', 'py' },
      { 'py', 'py=' },
    } do
      if vim.startswith(line, rule[1]) then
        return replace(rule[1], rule[2])
      end
    end
  end
  return ''
end, { expr = true, desc = 'Toggle Ex command: exec <-> eval' })
