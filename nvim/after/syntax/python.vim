" additional and custom syntax for python codes
" (NO LONGER USED; use treesitter highlighting for python)
" currently, this customization dependes on 'python-mode' and 'vim-python-enhanced-syntax'

" class definition: brighter blui-sh color
hi pythonClass          ctermfg=45      guifg=#00d7ff


" Highlight test_xxxx() methods and functions.
syntax match pythonTestCase "\<test_\w\+\ze" contained containedin=pythonFunction
hi pythonTestCase guifg=#ffff30 gui=bold


" nested syntax for inline snippets (e.g. bash script, etc.)
if expand('%:p:t') == 'install.py'
  " Note: this is buggy, breaking plain python syntax upon inclusion
  let csyn = b:current_syntax | unlet b:current_syntax
  syntax include @SH syntax/zsh.vim
  let b:current_syntax = csyn | unlet csyn

  syntax region pythonDocstringSnippetSh  matchgroup=pythonDocstringSnip
      \ start=+'''#!/bin/bash+ end=+'''+
      \ containedin=pythonDocstring contained contains=@SH

  hi! def link pythonDocstringSnip SpecialComment
endif

" Make sure that you have enough lines of context for correct highlighting (:help syn-sync),
" the zsh syntax file sets this to very small number, but we want larger context.
syn sync minlines=5000
