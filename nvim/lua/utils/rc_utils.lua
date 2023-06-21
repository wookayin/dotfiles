local M = {}

local augroup_RegisterHighlights

-- Similar as vim.fn.RegisterHighlights, but in lua.
M.RegisterHighlights = function(fn)
  fn()
  vim.api.nvim_create_autocmd('Colorscheme', {
    pattern = '*',
    group = augroup_RegisterHighlights,
    callback = function() fn() end,
  })
end
augroup_RegisterHighlights = vim.api.nvim_create_augroup('Colorscheme_RegisterHighlightsLua', { clear = true })


-- List bufnr for all the existing, listed buffers.
M.list_bufs = function()
  return vim.tbl_filter(function(buf)
    return (
      vim.api.nvim_buf_is_valid(buf) and
      vim.api.nvim_get_option_value('buflisted', { buf = buf })
    )
  end, vim.api.nvim_list_bufs())
end


-- Execute fn: fun(bufnr) for all the existing, listed buffers,
-- with bufnr being the current buffer when executing fn.
M.bufdo = function(fn)
  vim.tbl_map(function(buf)
    vim.api.nvim_buf_call(buf, function()
      fn(buf)
    end)
  end, M.list_bufs())
end

return M
