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

if !exists('g:plugs')
    " Probably not using the full vimrc/init.vim setup
    finish
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
    let l:pylintrc_path = filereadable(".pylintrc") ? ".pylintrc" : l:project_root . '/.pylintrc'
    if !filereadable(l:pylintrc_path)
      return -1  " no pylintrc found
    endif
    if !empty(systemlist("grep \"indent-string='  '\" " .. shellescape(l:pylintrc_path)))
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

" omnifunc is not used in favor of LSP, but just in case...
if has('python3')
  setlocal omnifunc=python3complete#Complete
endif


" shortcuts
" =========

" CTRL-B: insert breakpoint above?
imap <buffer> <C-B>   <ESC><leader>ba<Down>

if has_key(g:, 'plugs') && has_key(g:plugs, 'vim-surround')
  " Apply str(...) repr(...) to the current word or selection
  " :help surround-replacements
  nmap <buffer>  <leader>str   ysiwfstr<CR>
  vmap <buffer>  <leader>str   Sfstr<CR>
  nmap <buffer>  <leader>repr  ysiwfrepr<CR>
  vmap <buffer>  <leader>repr  Sfrepr<CR>
endif

" Fallback to jedi for providing gd/gr command
if has_key(g:, 'plugs') && has_key(g:plugs, 'jedi-vim')
  " goto definition (gd)
  noremap  <buffer> <F12>  :call jedi#goto_assignments()<CR>
  nmap     <buffer> <F3>   :call jedi#goto_assignments()<CR>
  inoremap <buffer> <F12>  :call jedi#goto_assignments()<CR>
  imap     <buffer> <F3>   :call jedi#goto_assignments()<CR>
  " show usages (gr)
  noremap  <buffer> <S-F12>  :call jedi#usages()<CR>
  inoremap <buffer> <S-F12>  :call jedi#usages()<CR>
endif

" comment annotations
function! ToggleLineComment(str)
  let l:comment = '# ' . a:str
  let l:line = getline('.')
  if l:line =~ (l:comment) . '$'
    " Already exists at the end: strip the comment
    call setline('.', TrimRight(l:line[:-(len(l:comment) + 1)]))
  else
    " or append it if there wasn't
    call setline('.', l:line . '  ' . l:comment)
  end
endfunction

function! s:define_toggle_mapping(name, comment) abort
  execute 'nmap <Plug>' . a:name . ' ' .
        \ ':<C-u>call ToggleLineComment("' . a:comment . '")<CR><bar>' .
        \ ':<c-u>silent! call repeat#set("\<Plug>' . a:name . '")<CR>'
endfunction
call s:define_toggle_mapping("ToggleLineComment_type_ignore", "type: ignore")
nmap <buffer> <leader>ti <Plug>ToggleLineComment_type_ignore
call s:define_toggle_mapping("ToggleLineComment_yapf_disable", "yapf: disable")
nmap <buffer> <leader>ty <Plug>ToggleLineComment_yapf_disable



" Experimental
" ============

" LSP: turn on auto formatting by default for a 'project'
" condition: when one have .style.yapf file in a git repository.
" Executed only once for the current vim session.
if exists(':LspAutoFormattingOn')
  if get(g:, '_python_autoformatting_detected', 0) == 0
    let g:_python_autoformatting_detected = 1  " do not auto-turn on any more
    let s:project_root = DetermineProjectRoot()
    if !empty(s:project_root)
      let s:style_yapf = s:project_root . '/.style.yapf'
      if filereadable(s:style_yapf)
        " TODO: Do not affect files outside the project!!
        execute ":LspAutoFormattingOn " . s:style_yapf
      endif
    endif
  endif
endif

" <Alt-Enter> for auto import symbol
if exists(':ImportSymbol')   " plugin vim-autoimport
  nmap <silent> <buffer>  <M-CR>   :ImportSymbol<CR>
  imap <silent> <buffer>  <M-CR>   <Esc>:ImportSymbol<CR>a
endif


let b:gps_available = exists('*luaeval') && luaeval(
            \ 'pcall(require, "nvim-gps") and require"nvim-gps".is_available()'
            \ )

function! s:test_suite_on_cursor() abort
  " Automatically extract the current test method or class (suite)
  if has_key(b:, 'lsp_current_function')
    return b:lsp_current_function
  elseif b:gps_available  " nvim-gps
    " TODO: This relies on dirty parsing. see nvim-gps#68
    let loc = split(luaeval('require"nvim-gps".get_location()'))
    for i in range(len(loc) - 1, 0, -1)
      if loc[i] =~# '^test' || loc[i] =~# '^Test'
        return loc[i]
      endif
    endfor
    return ''   " not found
  else | return '' | endif
endfunction

" <F5> to run &makeprg on a floaterm window (experimental)
" pytest or execute the script itself, as per &makeprg
let s:is_test_file = (expand('%:t:r') =~# "_test$" || expand('%:t:r') =~# '^test_')
if has_key(g:plugs, 'neotest-python') && s:is_test_file
  " see ~/.config/nvim/config/tesing.lua commands
  command! -buffer -nargs=0  Build    echom ':Test' | Test
  command! -buffer -nargs=0  Output   NeotestOutput

  nnoremap <buffer>    <leader>T   <cmd>NeotestSummary<CR>

elseif has_key(g:plugs, 'vim-floaterm')
  let s:ftname = 'makepython'
  function! MakeInTerminal() abort
    let l:bufnr = floaterm#terminal#get_bufnr(s:ftname)
    let l:CTRL_U = nr2char(21)
    let l:cmd = ExpandCmd(&makeprg)
    if get(b:, 'makeprg_pytest', 0)
      let l:pytest_pattern = s:test_suite_on_cursor()
      if !empty(l:pytest_pattern)
        let l:cmd = printf('pytest -s %s -k %s', expand('%:.'), shellescape(l:pytest_pattern))
      endif
    endif
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
