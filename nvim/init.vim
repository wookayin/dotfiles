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
if !filereadable(g:python_host_prog)
    " Fallback if not exists
    let g:python_host_prog = '/usr/bin/python2'
endif

let g:python3_host_prog = ''

if executable("python3")
  " get local python from $PATH (virtualenv/anaconda or system python)
  let s:python3_local = substitute(system("which python3"), '\n\+$', '', '')

  function! Python3_determine_pip_options()
    " On mac/miniconda/anaconda environments, do not use --user flag (NO ~/.local/bin)
    let l:pip_options = ''
    if !has('mac')
      let l:py_prefix = substitute(system("python3 -c 'import sys; print(sys.prefix)' 2>/dev/null"), '\n\+$', '', '')
      if l:py_prefix == "/usr" || l:py_prefix == "/usr/local"
        let l:pip_options = '--user'
      endif
    endif

    let l:pip_options .= ' --upgrade --ignore-installed'
    if has('mac')
      " mac: Force greenlet to be compiled from source due to potential architecture mismatch (pynvim#473)
      let l:pip_options = l:pip_options . ' --no-binary greenlet'
    endif
    return l:pip_options
  endfunction

  " Detect whether neovim package is installed; if not, automatically install it
  " Since checking pynvim is slow (~200ms), it should be executed after vim init is done.
  call timer_start(0, { -> s:autoinstall_pynvim() })
  function! s:autoinstall_pynvim()
    if empty(g:python3_host_prog) | return | endif
    let s:python3_neovim_path = substitute(system(g:python3_host_prog . " -c 'import pynvim; print(pynvim.__path__)' 2>/dev/null"), '\n\+$', '', '')
    if empty(s:python3_neovim_path)
      " auto-install 'neovim' python package for the current python3 (virtualenv, anaconda, or system-wide)
      let s:pip_options = Python3_determine_pip_options()
      execute ("!" . g:python3_host_prog . " -m pip install " . s:pip_options . " pynvim")
      if v:shell_error == 0
        echohl MoreMsg | echom "Successfully installed pynvim. Please restart neovim." | echohl NONE
      else
        call s:show_warning_message('ErrorMsg', "Installation of pynvim failed. Python-based features may not work.")
      endif
    endif
  endfunction

  " Assuming that pynvim package is available (or will be installed later), use it as a host python3
  let g:python3_host_prog = s:python3_local
else
  echoerr "python3 is not found on your system: Check $PATH or $SHELL. Most features are disabled."
  let s:python3_local = ''
endif

" Fallback to system python3 (if not exists)
if !filereadable(g:python3_host_prog) | let g:python3_host_prog = '/usr/local/bin/python3' | endif
if !filereadable(g:python3_host_prog) | let g:python3_host_prog = '/usr/bin/python3'       | endif
if !filereadable(g:python3_host_prog) | let g:python3_host_prog = s:python3_local          | endif

" Warn users if modern python3 is not found.
" (with timer, make it shown frontmost over other warning messages)
if empty(g:python3_host_prog)
  call timer_start(0, { -> s:show_warning_message('ErrorMsg',
        \ "ERROR: You don't have python3 on your $PATH. Check $PATH or $SHELL. Most features are disabled.")
        \ })
else
  " Get and validate python version
  " Make a dummy call first, to workaround a bug neovim#14438
  call py3eval("None")
  function! s:python3_version_check() abort
    if py3eval('sys.version_info < (3, 6)')
      call s:show_warning_message('ErrorMsg', "Your python version (" .
            \ py3eval('".".join(str(x) for x in sys.version_info)')
            \ . ") is too old; 3.6+ is required. Most features are disabled.")
    endif
  endfunction
  call timer_start(0, { -> s:python3_version_check() })
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


" Neovim: Execute lua config.
" See ~/.config/nvim/lua/config
if has('nvim-0.5')
  function! s:source_lua_configs(...)
lua << EOF
    require 'config/statusline'
    require 'config/lsp'
    require 'config/treesitter'
    require 'config/telescope'
    require 'config/folding'
    require 'config/testing'
EOF
  endfunction

  " All lua-based plugins will be loaded and set up lazily after Vim loads.
  " See vimrc:L10 for LazyInit
  autocmd User LazyInit
        \ call s:source_lua_configs() |
        \ call s:reload_buffers()    " this shouldn't run until init is done

  function! s:reload_buffers()
    " reattach LSP on all buffers, after reloading the LSP config
    if exists('*win_getid')  " neovim or vim 7.4.1557+
      let l:current_winid = win_getid()
      execute 'silent! windo if _is_file_buffer() | e | endif'
      call win_gotoid(l:current_winid)
    endif
  endfunction
endif
