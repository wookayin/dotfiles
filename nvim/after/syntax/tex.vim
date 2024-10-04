" additional and custom syntax for LaTeX documents

" Additional regions {{{

" treat \begin{comment}...\end{comment} region as comment
syn region texCommentRegion     start="\\begin{comment}"  end="\\end{comment}\|%stopzone\>"
hi! def link texCommentRegion   texComment

" treat \iffalse ... \fi as comment
syn region texIfFalseRegion     start="\\iffalse"  end="\\else\|\\fi\|%stopzone\>"
hi texIfFalseRegion             ctermfg=241 guifg=#626262

" TODO: nested region currently does not work

syn cluster texFoldGroup        add=texCommentRegion,texIfFalseRegion

syn match texCmdNum     '\\[0-9]\+'
hi def link texCmdNum   Special
" }}}


" more distinctive colors {{{
" ---------------------------

" texCommentRegion: similar to texComment (ctermfg=35) but slightly different color
hi texCommentRegion ctermfg=108     guifg=#87af5f

" \if, \else, \fi, ...
hi! link texCmdConditional      Special

" \eq{...}, \ref{...}
hi texRefZone       ctermfg=142     guifg=#afaf00

" math: use different (blue-ish) color than normal text
hi texMath          ctermfg=80      guifg=#5fd7d7

hi link     texMathSymbol       texMath
hi def link texGreek            texMath   |  hi texGreek            guifg=#38a5a5
hi link     texMathDelim        texMath
hi link     texMathOper         texMath

hi link     texSuperscript      texMath
hi link     texSubscript        texMath

" }}}
