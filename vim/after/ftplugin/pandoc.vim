setlocal expandtab
set ts=2
set sw=2
set sts=2

setlocal iskeyword+=_,:
setlocal conceallevel=0

" indentLine is never supposed to enable this for pandoc document,
" but in some situations it does. We always force disable indentLine.
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
command! -buffer   Grip Dispatch grip "%" 0.0.0.0

" vim-emoji
if has_key(g:plugs, 'vim-emoji')
  setlocal completefunc=emoji#complete
endif
