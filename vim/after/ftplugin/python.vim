" python.vim

if !filereadable('Makefile')
  if bufname('%') =~ '_test.py$'
    let &l:makeprg=printf('pytest %s', shellescape(expand("%")))
  else
    let &l:makeprg=printf('python %s', shellescape(expand("%")))
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
inoremap # X<BS>#

" LSP (coc.nvim) is used but just in case...
setlocal omnifunc=python3complete#Complete


" shortcuts
" =========

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
if exists(':ImportSymbol')
  nmap <silent> <buffer>  <M-CR>   :ImportSymbol<CR>
  imap <silent> <buffer>  <M-CR>   <Esc>:ImportSymbol<CR>a
endif
if exists(':CocCommand')
  command! -buffer ImportOrganize    :CocCommand python.sortImports
endif


" <F5> to run &makeprg on a floaterm window (experimental)
" pytest or execute the script itself, as per &makeprg
if has_key(g:plugs, 'vim-floaterm')
  let s:ftname = 'makepython'
  function! MakeInTerminal() abort
    let l:bufnr = floaterm#terminal#get_bufnr(s:ftname)
    let l:CTRL_U = nr2char(21)
    let l:cmd = l:CTRL_U . (&makeprg)
    if l:bufnr == -1
      let l:bufnr = floaterm#new(l:cmd,
            \ {'name': s:ftname, 'position': 'right', 'wintype': 'normal',
            \  'width': float2nr(&columns / 3.0), 'autoclose': 1}, {}, 1)
      tnoremap <buffer> <silent> <F6>  <c-\><c-n>:FloatermHide<CR>
      wincmd p        " move back to the python buf
    else
      call floaterm#terminal#send(l:bufnr, [l:cmd])
      " show the window (it could be either hidden or visible)
      " this works as we are currently on the 'python' buffer
      call floaterm#toggle(s:ftname)
      wincmd p        " move back to the python buf
    endif
  endfunction
  noremap <buffer>          <F5>   <ESC>:w<CR>:<C-u>call MakeInTerminal()<CR><C-\><C-o>:stopinsert<CR>
  noremap <buffer> <silent> <F6>   :FloatermToggle makepython<CR>
endif
