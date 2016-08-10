" Neovim configuration file :-)
" a.k.a ~/.nvimrc


" Specify python host (preferrably system default) for neovim.
" The 'neovim' package must be installed in that python:
" e.g. /usr/bin/pip install neovim
"  (or /usr/bin/pip3, /usr/local/bin/pip, depending environments)

let g:python_host_prog  = '/usr/bin/python'
if empty(glob("/usr/bin/python"))
    " Fallback if not exists (e.g. Python3 in macOS)
    let g:python_host_prog = '/usr/local/bin/python'
endif

let g:python3_host_prog = '/usr/bin/python3'
if empty(glob("/usr/bin/python3"))
    " Fallback if not exists (e.g. Python3 in macOS)
    let g:python3_host_prog = '/usr/local/bin/python3'
endif


" delegate to the plain vimrc.
source ~/.vimrc

set rtp+=~/.vim
