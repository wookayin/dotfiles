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

return M
