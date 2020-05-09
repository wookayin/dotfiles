" python.vim

if !filereadable('Makefile')
  if bufname('%') =~ '_test.py$' || expand('%:t') =~ '^test_.*\.py'
    let &l:makeprg='pytest "%" -s'
    let b:makeprg_pytest = 1
  else
    let &l:makeprg='python "%"'
    let b:makeprg_pytest = 0
  endif
endif

if has_key(g:plugs, 'neomake')
  " Neomake's python runner only does linting. But we would rather want to run it.
  command! -buffer -bang Neomake  call neomake#ShCommand(<bang>0, &makeprg)
endif

setlocal expandtab
setlocal ts=4
setlocal sw=4
setlocal sts=4

setlocal cc=80
setlocal tw=100

" braceless.vim
silent! BracelessEnable +indent +highlight

" For python, exclude 'longest' from completeopt in order
" to prevent underscore prefix auto-completion (e.g. self.__)
" @see jedi-vim issues #429
" @see g:jedi#auto_vim_configuration
set completeopt-=longest

" Prevent vim from removing indentation on python comments
" https://stackoverflow.com/questions/2360249/
inoremap <buffer> # X<BS>#

" LSP (coc.nvim) is used but just in case...
if has('python3')
  setlocal omnifunc=python3complete#Complete
endif


" shortcuts
" =========

if has_key(g:, 'plugs') && has_key(g:plugs, 'vim-surround')
  " Apply str(...) repr(...) to the current word or selection
  " :help surround-replacements
  nmap <buffer>  <leader>str   ysiwfstr<CR>
  vmap <buffer>  <leader>str   Sfstr<CR>
  nmap <buffer>  <leader>repr  ysiwfrepr<CR>
  vmap <buffer>  <leader>repr  Sfrepr<CR>
endif

" if coc.nvim is available, use the global shortcut
" (see ~/.vimrc for the global mapping of <F3> key)
if !has_key(g:, 'plugs') || !has_key(g:plugs, 'coc.nvim')
    " goto definition
    map  <F3> :call jedi#goto_assignments()<CR>
    imap <F3> <ESC>:call jedi#goto_assignments()<CR>
    " show usages
    map <F7> :call jedi#usages()<CR>
    imap <F7> <ESC>:call jedi#usages()<CR>
endif


" Experimental
" ============

" <M-CR> for auto import symbol (replacing coc.nvim)
if exists(':ImportSymbol')   " plugin vim-autoimport
  nmap <silent> <buffer>  <M-CR>   :ImportSymbol<CR>
  imap <silent> <buffer>  <M-CR>   <Esc>:ImportSymbol<CR>a
endif
if exists(':CocCommand')
  command! -buffer ImportOrganize    :CocCommand python.sortImports
endif


function! s:method_on_cursor() abort
  " try to automatically get the current function
  if exists('*CocAction')
    return CocAction('getCurrentFunctionSymbol')
  else | return '' | endif
endfunction

" <F5> to run &makeprg on a floaterm window (experimental)
" pytest or execute the script itself, as per &makeprg
if has_key(g:plugs, 'vim-floaterm')
  let s:ftname = 'makepython'
  function! MakeInTerminal() abort
    let l:bufnr = floaterm#terminal#get_bufnr(s:ftname)
    let l:CTRL_U = nr2char(21)
    let l:cmd = ExpandCmd(&makeprg)
    if get(b:, 'makeprg_pytest', 0)
      let l:pytest_pattern = s:method_on_cursor()
      if !empty(l:pytest_pattern)
        let l:cmd = printf('pytest -s -k %s', shellescape(l:pytest_pattern))
      endif
    endif
    if l:bufnr == -1
      let l:bufnr = floaterm#new(l:cmd,
            \ {'name': s:ftname, 'position': 'right', 'wintype': 'normal',
            \  'width': float2nr(&columns / 3.0), 'autoclose': 1}, {}, 1)
      tnoremap <buffer> <silent> <F6>  <c-\><c-n>:FloatermHide<CR>
      wincmd p        " move back to the python buf
    else
      call floaterm#terminal#send(l:bufnr, [l:CTRL_U . l:cmd])
      " show the window (it could be either hidden or visible)
      " this works as we are currently on the 'python' buffer
      call floaterm#toggle(s:ftname)
      wincmd p        " move back to the python buf
    endif
  endfunction
  noremap <buffer>          <F5>   <ESC>:w<CR>:<C-u>call MakeInTerminal()<CR><C-\><C-o>:stopinsert<CR>
  noremap <buffer> <silent> <F6>   :FloatermToggle makepython<CR>
endif
