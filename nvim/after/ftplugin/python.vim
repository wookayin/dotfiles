" python.vim: python ftplugin
" (see also python.lua)

if !filereadable('Makefile')
    let &l:makeprg='python "%"'
endif

setlocal expandtab
setlocal ts=4
setlocal sw=4
setlocal sts=4

setlocal colorcolumn=+1
setlocal textwidth=79

" disable automatic line wrap in normal text, in favor of formatters (yapf)
setlocal formatoptions-=t
" but auto-wrap comments after 79 characters
setlocal formatoptions+=c


if !exists('g:plugs') && !exists('g:lazy_did_setup')
    " Probably not using plugins, disable ftplugins
    finish
endif

if has('nvim')
  " TODO: Remove this config, should use .editorconfig
  function! AutoTabsizePython(...) abort
    let l:project_root = DetermineProjectRoot()
    let l:pylintrc_path = filereadable(".pylintrc") ? ".pylintrc" : l:project_root . '/.pylintrc'
    if !filereadable(l:pylintrc_path)
      return -1  " no pylintrc found
    endif
    if !empty(systemlist("grep \"^indent-string='  '\" " .. shellescape(l:pylintrc_path)))
      setlocal ts=2 sw=2 sts=2
      return 2  " Use tabsize 2
    endif
    return 0   " no config found, don't touch tabsize
  endfunction
  call timer_start(0, function('AutoTabsizePython'))
endif

" For python, exclude 'longest' from completeopt in order
" to prevent underscore prefix auto-completion (e.g. self.__)
" @see jedi-vim issues #429
" @see g:jedi#auto_vim_configuration
set completeopt-=longest

" No omnifunc needed, we are backed by LSP
set omnifunc=

" Prevent vim from removing indentation on python comments
" https://stackoverflow.com/questions/2360249/
inoremap <buffer> # X<BS>#

function! s:pcall_require(name) abort
  if !has('nvim') | return 0 | endif
  return luaeval('pcall(require, _A)', a:name)
endfunction

" shortcuts
" =========

" CTRL-B: insert breakpoint above?
imap <buffer> <C-B>   <ESC><leader>ba<Down>

if 1  " TODO: HasPlug('vim-surround')
  " Apply str(...) repr(...) to the current word or selection
  " :help surround-replacements
  nmap <buffer>  <leader>str   ysiwfstr<CR>
  vmap <buffer>  <leader>str   Sfstr<CR>
  nmap <buffer>  <leader>repr  ysiwfrepr<CR>
  vmap <buffer>  <leader>repr  Sfrepr<CR>
endif



" Experimental
" ============

" <Alt-Enter> for auto import symbol
if exists(':ImportSymbol')   " plugin vim-autoimport
  nmap <silent> <buffer>  <M-CR>   :ImportSymbol<CR>
  imap <silent> <buffer>  <M-CR>   <Esc>:ImportSymbol<CR>a
endif


" <F5> to run &makeprg on a floaterm window (experimental)
" pytest or execute the script itself, as per &makeprg
let s:is_test_file = (expand('%:t:r') =~# "_test$" || expand('%:t:r') =~# '^test_')
if s:is_test_file && s:pcall_require('neotest')
  " see ~/.config/nvim/config/tesing.lua commands
  command! -buffer -nargs=0  Build    echom ':Test' | Test
  command! -buffer -nargs=0  Output   NeotestOutput

  nnoremap <buffer>    <leader>T   <cmd>NeotestSummary<CR>

elseif filereadable('Makefile')

elseif exists('g:loaded_floaterm')
  let s:ftname = 'makepython'
  function! MakeInTerminal() abort
    let l:bufnr = floaterm#terminal#get_bufnr(s:ftname)
    let l:CTRL_U = nr2char(21)
    let l:cmd = ExpandCmd(&makeprg)
    if l:bufnr == -1
      " floaterm#new(bang, cmd, winopts, jobopts)
      " floaterm API is fucking capricious and not sensible :(
      if &columns / (&lines + 0.0) >= 1.6
        " vertical split (put in the right)
        let l:winopt = {
              \ 'position': 'right', 'wintype': 'vsplit',
              \ 'width': float2nr(&columns / 3.0)}
      else
        " horizontal split (put in the below)
        let l:winopt = {
              \ 'position': 'below', 'wintype': 'split',
              \ 'height': float2nr(&lines / 5.0)}
      endif
      " floaterm#new(bang, cmd, jobopts, opts) -- this API keeps changing...  :(
      let l:winopt = extend(l:winopt, {'name': s:ftname, 'autoclose': 1})
      let l:bufnr = floaterm#new(1, l:cmd, {}, l:winopt)
      tnoremap <buffer> <silent> <F6>  <c-\><c-n>:FloatermHide<CR>
      wincmd p        " move back to the python buf
    else
      call floaterm#terminal#send(l:bufnr, [l:CTRL_U . l:cmd])
      " show the window (it could be either hidden or visible)
      " this works as we are currently on the 'python' buffer
      call floaterm#toggle(0, 0, s:ftname)
      wincmd p        " move back to the python buf
    endif
  endfunction
  " <F5> Build (replaces Make), <F6> Output (replaces QuickfixToggle)
  command! -buffer -bar  Build   w | call MakeInTerminal() | stopinsert
  command! -buffer -bar  Output  FloatermShow makepython
endif
