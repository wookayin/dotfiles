" python.vim

if !filereadable('Makefile')
    let &l:makeprg="python %"
endif

setlocal expandtab
setlocal ts=4
setlocal sw=4
setlocal sts=4
setlocal cc=80

" braceless.vim
BracelessEnable +indent +highlight

" shortcuts
" =========

" goto definition
map  <F3> :call jedi#goto()<CR>
imap <F3> <ESC>:call jedi#goto()<CR>
