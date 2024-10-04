-- Docs: $VIMPLUG/neorepl.nvim/doc/neorepl.txt

local bufnr = vim.fn.bufnr()

-- highlight override for NeoREPL output
local highlight = vim.api.nvim_set_hl
highlight(0, 'neoreplOutput', { fg = 'NONE', bg = '#202020' })
highlight(0, 'neoreplValue',  { fg = 'NONE', bg = '#101a10' })
highlight(0, 'neoreplError',  { fg = 'NONE', bg = '#371515' })


local disable_cmp = function()
  pcall(function()
    require('cmp').setup.buffer { enabled = false }
  end)
end

local set_keymap = function()
  local bufmap = function(mode, lhs, rhs, opt)
    return vim.keymap.set(mode, lhs, rhs,
      vim.tbl_deep_extend("force", { remap = false, buffer = true }, opt or {}))
  end

  -- See require('neorepl.map')
  bufmap('i', '<Tab>', function()
    return vim.fn.pumvisible() > 0 and '<C-n>' or '<Plug>(neorepl-complete)'
  end, { expr = true })
  bufmap('i', '<S-Tab>', function()
    return vim.fn.pumvisible() > 0 and '<C-p>' or '<S-Tab>'
  end, { expr = true })
  bufmap('i', '<CR>', function()
    return vim.fn.pumvisible() > 0 and '<C-y>' or '<C-g>u<Plug>(neorepl-eval-line)'
  end, { expr = true })
  bufmap('i', '<C-M>', function()
    return vim.fn.pumvisible() > 0 and '<C-y>' or '<C-g>u<Plug>(neorepl-eval-line)'
  end, { expr = true })
  bufmap('i', '<C-space>', '<Plug>(neorepl-complete)')
  bufmap('i', '<C-l>', function() require 'neorepl.buf'.clear(bufnr) end)
  bufmap('i', '<C-k>', '<cmd>stopinsert<CR><c-k>', { remap = true })
  bufmap('i', '<C-h>', '<cmd>stopinsert<CR><c-h>', { remap = true })
end

-- Disable cmp
do
  disable_cmp()
  set_keymap()

  -- Workaround for "cmp overrides keymap despite being disabled"
  vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertEnter' }, {
    desc = 'Override keymaps for NeoREPL',
    buffer = bufnr,
    callback = function()
      disable_cmp()
      set_keymap()
      vim.cmd [[ startinsert ]]
    end,
  })

  -- Syntax support by treesitter
  if vim.treesitter and pcall(require, 'nvim-treesitter') then
    vim.treesitter.start(bufnr, 'lua')
  end
end
