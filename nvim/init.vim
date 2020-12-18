" Neovim configuration file :-)
" a.k.a ~/.nvimrc

" vim: set ts=2 sts=2 sw=2:

function! s:show_warning_message(hlgroup, msg)
    execute 'echohl ' . a:hlgroup
    echom a:msg | echohl None
endfunction

" Specify python host (preferrably system default) for neovim.
" The 'neovim' package must be installed in that python:
" e.g. /usr/bin/pip install neovim
"  (or /usr/bin/pip3, /usr/local/bin/pip, depending environments)
" The locally installed python (e.g. homebrew) at /usr/local/bin precedes.

let g:python_host_prog  = '/usr/local/bin/python2'
if empty(glob(g:python_host_prog))
    " Fallback if not exists
    let g:python_host_prog = '/usr/bin/python2'
endif

let g:python3_host_prog = ''

if executable("python3")
  " get local python from $PATH (virtualenv/anaconda or system python)
  let s:python3_local = substitute(system("which python3"), '\n\+$', '', '')

  function! Python3_determine_pip_options()
    let l:pip_options = '--user --upgrade '
    if empty(substitute(system("python3 -c 'import site; print(site.getusersitepackages())' 2>/dev/null"), '\n\+$', '', ''))
      " virtualenv pythons may not have site-packages, hence no 'pip -user'
      let l:pip_options = '--upgrade '
    endif
    return l:pip_options
  endfunction

  " Detect whether neovim package is installed; if not, automatically install it
  " Since checking pynvim is slow (~200ms), it should be executed after vim init is done.
  call timer_start(0, { -> s:autoinstall_pynvim() })
  function! s:autoinstall_pynvim()
    let s:python3_neovim_path = substitute(system(g:python3_host_prog . " -c 'import pynvim; print(pynvim.__path__)' 2>/dev/null"), '\n\+$', '', '')
    if empty(s:python3_neovim_path)
      " auto-install 'neovim' python package for the current python3 (virtualenv, anaconda, or system-wide)
      let s:pip_options = Python3_determine_pip_options()
      execute ("!" . s:python3_local . " -m pip install " . s:pip_options . " pynvim")
      if v:shell_error != 0
        call s:show_warning_message('ErrorMsg', "Installation of pynvim failed. Python-based features may not work.")
      endif
    endif
  endfunction

  " Assuming that pynvim package is available (or will be installed later), use it as a host python3
  let g:python3_host_prog = s:python3_local
else
  echoerr "python3 is not found on your system. Most features are disabled."
  let s:python3_local = ''
endif

" On M1 mac, neovim and python3 can have different architecture.
let s:uname = substitute(system('uname -s'), '\n', '', '')
if s:uname ==? 'Darwin' && !empty(g:python3_host_prog)
  if substitute(system("uname -m"), '\n\+$', '', '') !=
        \ substitute(system("lipo -archs " . g:python3_host_prog), '\n\+$', '', '')
    echomsg "WARNING: neovim and python3 have different architecture (arm64 vs x86_64). Falling back to intel python3 on /usr/local ..."
    let g:python3_host_prog = ''
  endif
endif

" Fallback to system python3 (if not exists)
if empty(glob(g:python3_host_prog)) | let g:python3_host_prog = '/usr/local/bin/python3' | endif
if empty(glob(g:python3_host_prog)) | let g:python3_host_prog = '/usr/bin/python3'       | endif
if empty(glob(g:python3_host_prog)) | let g:python3_host_prog = s:python3_local          | endif

" Get and validate python version
try
  if executable('python3')
    let g:python3_host_version = split(system("python3 --version 2>&1"))[1]   " e.g. Python 3.7.0 :: Anaconda, Inc.
  else | let g:python3_host_version = ''
  endif
catch
  let g:python3_host_version = ''
endtry

" Warn users if modern python3 is not found.
" (with timer, make it shown frontmost over other warning messages)
if empty(g:python3_host_version)
  call timer_start(0, { -> s:show_warning_message('ErrorMsg',
        \ "ERROR: You don't have python3 on your $PATH. Most features are disabled.")
        \ })
elseif g:python3_host_version < '3.6.1'
  call timer_start(0, { -> s:show_warning_message('WarningMsg',
        \ printf("Warning: Please use python 3.6.1+ to enable intellisense features. (Current: %s)", g:python3_host_version))
        \ })
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
