" additional and custom syntax for LaTeX documents

" treat \begin{comment}...\end{comment} region as comment
syn region texComment     start="\\begin{comment}"  end="\\end{comment}\|%stopzone\>"


" more distinctive colors {{{

" \eq{...}, \ref{...}
hi texRefZone       ctermfg=142     guifg=#afaf00

" math: use different (blue-ish) color than normal text
hi texMath          ctermfg=80      guifg=#5fd7d7

hi link texMathSymbol       texMath
hi link texGreek            texMath
hi link texMathDelim        texMath
hi link texMathOper         texMath

hi link texSuperscript      texMath
hi link texSubscript        texMath

" }}}
