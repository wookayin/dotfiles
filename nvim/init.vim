" Neovim configuration file :-)
" a.k.a ~/.nvimrc

" the default (system) python to use.
" That python should have 'neovim' package: e.g. /usr/bin/pip install neovim
let g:python_host_prog = '/usr/bin/python'
let g:python3_host_prog = '/usr/bin/python3'


" delegate to the plain vimrc.
source ~/.vimrc

set rtp+=~/.vim
