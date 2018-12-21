" additional and custom syntax for python codes
" currently, this customization dependes on 'python-mode' and 'vim-python-enhanced-syntax'

" Use brighter color for method/function definition
hi pythonFunction       ctermfg=191     guifg=#d7ff5f
hi pythonParam          ctermfg=229     guifg=#ffffaf

" class definition: brighter blui-sh color
hi pythonClass          ctermfg=45      guifg=#00d7ff

" self: more distinctive color
hi pythonSelf           ctermfg=174     guifg=#d78787
hi semshiSelf           ctermfg=174     guifg=#d78787

" attribute (self.xxx)
hi semshiAttribute      ctermfg=157     guifg=#afffaf


" docstring: gray-ish?
hi SpecialComment       ctermfg=250     guifg=#99a899


" nested syntax for inline snippets
" e.g. bash script, etc.
let csyn = b:current_syntax | unlet b:current_syntax
syntax include @SH syntax/zsh.vim
let b:current_syntax = csyn | unlet csyn

syntax region pythonDocstringSnippetSh  matchgroup=pythonDocstringSnip
    \ start=+'''#!/bin/bash+ end=+'''+
    \ containedin=pythonDocString contained contains=@SH

hi! def link pythonDocstringSnip SpecialComment
