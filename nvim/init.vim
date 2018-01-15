" Neovim configuration file :-)
" a.k.a ~/.nvimrc


" Specify python host (preferrably system default) for neovim.
" The 'neovim' package must be installed in that python:
" e.g. /usr/bin/pip install neovim
"  (or /usr/bin/pip3, /usr/local/bin/pip, depending environments)
" The locally installed python (e.g. homebrew) at /usr/local/bin precedes.

let g:python_host_prog  = '/usr/local/bin/python'
if empty(glob(g:python_host_prog))
    " Fallback if not exists
    let g:python_host_prog = '/usr/bin/python'
endif

let g:python3_host_prog = '/usr/local/bin/python3'
if empty(glob(g:python3_host_prog))
    " Fallback if not exists
    let g:python3_host_prog = '/usr/bin/python3'
endif
if empty(glob(g:python3_host_prog)) && executable("python3")
    " Fallback to local/venv python3 if not exists
    let g:python3_host_prog = substitute(system("which python3"), '\n\+$', '', '')
endif

" VimR support {{{
" @see https://github.com/qvacua/vimr/wiki#initvim
if has('gui_vimr')
    set termguicolors
    set title
endif
" }}}

" delegate to the plain vimrc.
source ~/.vimrc

set rtp+=~/.vim
