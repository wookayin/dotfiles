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

if exists('*timer_start')
  function! AutoTabsizePython(...) abort
    let l:project_root = DetermineProjectRoot()
    if !filereadable(l:project_root . '/.pylintrc')
      return -1  " no pylintrc found
    endif
    if !empty(systemlist("grep", "indent-string='  '",
          \ (l:project_root . '/.pylintrc')))
      setlocal ts=2 sw=2 sts=2
      return 2  " Use tabsize 2
    endif
    return 0   " no config found, don't touch tabsize
  endfunction
  call timer_start(0, function('AutoTabsizePython'))
endif

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

" Fallback to jedi for providing gd/gr command
if has_key(g:, 'plugs') && !has_key(g:plugs, 'coc.nvim') && has_key(g:plugs, 'jedi-vim')
  " goto definition (gd)
  noremap  <buffer> <F12>  :call jedi#goto_assignments()<CR>
  nmap     <buffer> <F3>   :call jedi#goto_assignments()<CR>
  inoremap <buffer> <F12>  :call jedi#goto_assignments()<CR>
  imap     <buffer> <F3>   :call jedi#goto_assignments()<CR>
  " show usages (gr)
  noremap  <buffer> <F24>  :call jedi#usages()<CR>
  inoremap <buffer> <F24>  :call jedi#usages()<CR>
endif


" Experimental
" ============

" <M-CR> for auto import symbol (replacing coc.nvim)
if exists(':ImportSymbol')   " plugin vim-autoimport
  nmap <silent> <buffer>  <M-CR>   :ImportSymbol<CR>
  imap <silent> <buffer>  <M-CR>   <Esc>:ImportSymbol<CR>a
endif
if exists(':CocCommand')
  command! -buffer SortImport        :CocCommand python.sortImports
  command! -buffer ImportSort        :SortImport
  command! -buffer ImportOrganize    :SortImport
endif


function! s:method_on_cursor() abort
  " try to automatically get the current function
  if has_key(b:, 'lsp_current_function')
    return b:lsp_current_function
  elseif exists('*CocAction')
    let l:symbol = CocAction('getCurrentFunctionSymbol')
    " coc has a bug where unicode item kind labels appear; strip it
    return substitute(l:symbol, '^[^a-z]\s*', '', '')
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
      " floaterm#new(bang, cmd, winopts, jobopts)
      if &columns / (&lines + 0.0) >= 1.6
        let l:winopt = {'position': 'right', 'width': float2nr(&columns / 3.0)}
      else
        let l:winopt = {'position': 'below', 'height': float2nr(&lines / 5.0)}
      endif
      " floaterm#new(bang, cmd, jobopts, opts) -- this API keeps changing...  :(
      let l:bufnr = floaterm#new(1, l:cmd, {},
            \ extend(l:winopt, {
            \   'name': s:ftname, 'wintype': 'normal',
            \   'autoclose': 1})
            \)
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
  noremap <buffer>          <F5>   <ESC>:w<CR>:<C-u>call MakeInTerminal()<CR><C-\><C-o>:stopinsert<CR>
  noremap <buffer> <silent> <F6>   :FloatermToggle makepython<CR>
endif
