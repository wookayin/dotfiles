-- ftplugin/markdown

local setlocal = vim.opt_local

setlocal.expandtab = true
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2

setlocal.iskeyword:append({'_', ':'})

-- do not use conceal (for now)
setlocal.conceallevel = 0

-- Use treesitter highlight.
require("config.treesitter").ensure_parsers_installed { "markdown" }
require("config.treesitter").setup_highlight("markdown")


-- GFM markdown preview using grip
-- (pip install grip)
vim.cmd [[
  command! -buffer   Grip AsyncRun grip "%" 0.0.0.0
]]

-- Markdown headings-
vim.cmd [[
  nnoremap <buffer> <leader>1 m`yypVr=``
  nnoremap <buffer> <leader>2 m`yypVr-``
  nnoremap <buffer> <leader>3 m`^i### <esc>``4l
  nnoremap <buffer> <leader>4 m`^i#### <esc>``5l
  nnoremap <buffer> <leader>5 m`^i##### <esc>``6l
]]
