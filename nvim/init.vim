" Neovim configuration file :-)
" a.k.a ~/.nvimrc

" the default (system) python to use.
" That python should have 'neovim' package: e.g. /usr/bin/pip install neovim
let g:python_host_prog = '/usr/bin/python'

" delegate to the plain vimrc.
source ~/.vimrc

set rtp+=~/.vim
