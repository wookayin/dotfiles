-- Keymaps (plugin-agnostic)

-- Note: noremap = true (remap = false) by default
local nmap = function(...) vim.keymap.set('n', ...) end
local imap = function(...) vim.keymap.set('i', ...) end
local cmap = function(...) vim.keymap.set('c', ...) end
local xmap = function(...) vim.keymap.set('x', ...) end


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
      { 'python=', 'python' },
      { 'python', 'python=' },
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
