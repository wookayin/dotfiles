setlocal expandtab
set ts=4
set sw=4
set sts=4

setlocal iskeyword+=_,:

if !filereadable('Makefile')
    let &g:makeprg = "pandoc % -t latex -o %:r.pdf"
endif

" Markdown headings
nnoremap <leader>1 m`yypVr=``
nnoremap <leader>2 m`yypVr-``
nnoremap <leader>3 m`^i### <esc>``4l
nnoremap <leader>4 m`^i#### <esc>``5l
nnoremap <leader>5 m`^i##### <esc>``6l

" GFM markdown preview using grip
" (pip install grip)
command! Grip Dispatch grip % 0.0.0.0

" vim-emoji
if has_key(g:plugs, 'vim-emoji')
  setlocal completefunc=emoji#complete
endif
