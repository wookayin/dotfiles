-- ftplugin/vim.lua

vim.cmd [[ setlocal ts=2 sts=2 sw=2 ]]

-- neovim#20456: vim syntax for lua files are broken in neovim 0.8+
-- Use treesitter highlight for vimscripts.
require('config.treesitter').setup_highlight('vim')

--- :SourceThis
--- keys: <F5>, <leader>so
vim.api.nvim_buf_create_user_command(0, 'SourceThis', function(opts)
  vim.cmd.source('%')
  vim.notify("Sourced " .. vim.fn.bufname('%'), vim.log.levels.INFO, { title = 'SourceThis' })
end, { desc = 'SourceThis' })

vim.keymap.set('n', '<F5>',       '<cmd>SourceThis<CR>', { buffer = true })
vim.keymap.set('n', '<leader>so', '<cmd>SourceThis<CR>', { buffer = true })
vim.keymap.set('x', '<leader>so', function()
  local vstart = assert(vim.fn.getpos("v"))
  local vend = assert(vim.fn.getpos("."))
  local line_start = vstart[2]
  local line_end = vend[2]
  if line_start > line_end then
    line_start, line_end = line_end, line_start
  end
  local lines = vim.api.nvim_buf_get_lines(0, line_start - 1, line_end, true)
  vim.schedule(function()
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, {
      title = 'Sourced visual selection', lang = 'vim',
    })
  end)

  -- source the visual selection range
  return ':so<CR>'
end, { buffer = true, expr = true })
