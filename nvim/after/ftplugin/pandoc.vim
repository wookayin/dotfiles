setlocal expandtab
set ts=2
set sw=2
set sts=2

setlocal iskeyword+=_,:
setlocal conceallevel=0

" experimental treesitter highlight
if has('nvim-0.9')
lua << EOF
  if pcall(require, 'nvim-treesitter') then
    vim.treesitter.start(0, 'markdown')
    -- Use additional vim regex syntax, because some syntax (e.g. link) and
    -- pandoc extensions (e.g. HTML tags) are not supported by treesitter.
    vim.bo.syntax = "ON"
  end
EOF
endif


" indentLine is never supposed to be enabled for pandoc document,
" but somehow it often gets turned on. We always force disable indentLine.
let b:indentLine_enabled = 0

if !filereadable('Makefile')
    let &l:makeprg = 'pandoc % -t latex -o "%:r".pdf'
endif

" Markdown headings
nnoremap <leader>1 m`yypVr=``
nnoremap <leader>2 m`yypVr-``
nnoremap <leader>3 m`^i### <esc>``4l
nnoremap <leader>4 m`^i#### <esc>``5l
nnoremap <leader>5 m`^i##### <esc>``6l

" GFM markdown preview using grip
" (pip install grip)
command! -buffer   Grip AsyncRun grip "%" 0.0.0.0

" vim-emoji
if has_key(g:plugs, 'vim-emoji')
  setlocal completefunc=emoji#complete
endif
