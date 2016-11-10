" additional and custom syntax for python codes
"

" python docstring (not String)
hi! def link  pythonDocstring    SpecialComment

" Use brighter color for method/function definition
hi pythonFunction       ctermfg=191     guifg=#d7ff5f
hi pythonParam          ctermfg=229     guifg=#ffffaf



" Additional python syntax customization {{{
" ------------------------------------------

" python call syntax support
" (why not in python-mode?)

" TODO builtin call not working; e.g. dict() str() sorted()
syn match   pythonCall           /\<\h\w*\ze\%(\s*(\)/       contains=pythonBuiltinFunc,pythonBultinType nextgroup=pythonCallRegion skipwhite
syn region  pythonCallRegion     contained matchgroup=pythonParamsDelim
                            \ start="(" skip=+\(".*"\|'.*'\)+ end=")"
                            \ contains=pythonCallArguments transparent keepend
hi! link    pythonParamsDelim Delimiter

" TODO introduce @pythonExpr cluster (but not in python-mode ...)
syn match   pythonCallArguments     "[^,]*" contained contains=pythonCallArgument skipwhite
syn match   pythonCallArgument      "[^,]*" contained contains=pythonOperator,pythonExtraOperator,pythonLambdaExpr,pythonRepeat,pythonBuiltinObj,pythonBuiltinType,pythonConstant,pythonString,pythonNumber,pythonBrackets,pythonSelf,pythonDocstring,pythonComment,pythonCallArgumentKW,pythonCall skipwhite

" dict-style argumetn passing in python function call
syn match   pythonCallArgumentKW    contained /\h\w*\s*==\@!/ contains=pythonKWAssign
"hi! link   pythonCallArgumentKW    Special
hi          pythonCallArgumentKW    ctermfg=179     guifg=#dfaf5f

syn match   pythonKWAssign          /=/ contained
hi! link    pythonKWAssign          Operator
" }}}
