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
silent! BracelessEnable +indent +highlight

" For python, exclude 'longest' from completeopt in order
" to prevent underscore prefix auto-completion (e.g. self.__)
" @see jedi-vim issues #429
" @see g:jedi#auto_vim_configuration
set completeopt-=longest


" shortcuts
" =========

" goto definition
map  <F3> :call jedi#goto_assignments()<CR>
imap <F3> <ESC>:call jedi#goto_assignments()<CR>

" show usages
map <F7> :call jedi#usages()<CR>
imap <F7> <ESC>:call jedi#usages()<CR>
