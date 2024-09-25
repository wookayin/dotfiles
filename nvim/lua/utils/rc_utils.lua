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


---A shorthand to nvim_replace_termcodes() to use with nvim_feedkeys().
---Typically used as:
---  local t = require("utils.rc_utils").replace_termcodes
---  vim.api.nvim_feedkeys(t "<cmd>echom 'hi'<CR>", 'n', false)
---@param key_sequence string
M.replace_termcodes = function(key_sequence)
  do_lt = true  -- also translate `<lt>` => `<`
  special = true  -- replace |keycodes|, e.g. <CR>, <Esc>, <Nop>, <F1>, <C-...>
  return vim.api.nvim_replace_termcodes(key_sequence, true, do_lt, special)
end

---A shorthand to nvim_feedkeys(), where keycodes are yet to be replaced.
---@param key_sequence string
---@param mode string? mode flags (m n t i x), see :help feedkeys(). By default, 'n' (no remap).
M.exec_keys = function(key_sequence, mode)
  local t = M.replace_termcodes
  vim.api.nvim_feedkeys(t(key_sequence), mode or 'n', false)
end

---Register a global internal keymap that wraps `rhs` to be repeatable.
---@param mode string|table keymap mode, see vim.keymap.set()
---@param lhs string lhs of the internal keymap to be created, should be in the form `<Plug>(...)`
---@param rhs string|function rhs of the keymap, see vim.keymap.set()
---@return string The name of a registered internal `<Plug>(name)` keymap. Make sure you use { remap = true }.
M.make_repeatable_keymap = function (mode, lhs, rhs)
  vim.validate {
    mode = { mode, { 'string', 'table' } },
    rhs = { rhs, { 'string', 'function' },
    lhs = { name = 'string' } }
  }
  if not vim.startswith(lhs, "<Plug>") then
    error("`lhs` should start with `<Plug>`, given: " .. lhs)
  end
  if type(rhs) == 'string' then
    vim.keymap.set(mode, lhs, function()
      vim.fn['repeat#set'](vim.api.nvim_replace_termcodes(lhs, true, true, true))
      return rhs
    end, { buffer = false, expr = true })
  else
    vim.keymap.set(mode, lhs, function()
      rhs()
      vim.fn['repeat#set'](vim.api.nvim_replace_termcodes(lhs, true, true, true))
    end, { buffer = false })
  end
  return lhs
end


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

_G.rc_utils = M
return M
