-- Config for folding

local M = {}

--- Common config for folding.
function M.setup()
  -- Workaround for neovim/neovim#20726: Ctrl-C on terminal can make neovim hang
  vim.cmd [[
    augroup terminal_disable_fold
      autocmd!
      autocmd TermOpen * setlocal foldmethod=manual foldexpr=0
    augroup END
  ]]

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'  -- requires NVIM 0.11+

  -- highlighted foldtext
  vim.opt.foldtext = ''
  vim.opt.fillchars:append({ fold = ' ' })
end


M.setup()

return M
