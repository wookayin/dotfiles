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


let g:python3_host_prog = ''

if executable("python3")
    " get local python from $PATH (virtualenv/anaconda or system python)
    let s:python3_local = substitute(system("which python3"), '\n\+$', '', '')
    " detect whether neovim package is installed
    let s:python3_neovim_path = substitute(system("python3 -c 'import neovim; print(neovim.__path__)' 2>/dev/null"), '\n\+$', '', '')
    if !empty(s:python3_neovim_path)
        " neovim available, use it as a host python3
        let g:python3_host_prog = s:python3_local
    endif
else
    let s:python3_local = ''
endif

" Fallback to system python3 (if not exists)
if empty(glob(g:python3_host_prog)) | let g:python3_host_prog = '/usr/local/bin/python3' | endif
if empty(glob(g:python3_host_prog)) | let g:python3_host_prog = '/usr/bin/python3'       | endif
if empty(glob(g:python3_host_prog)) | let g:python3_host_prog = s:python3_local          | endif

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
