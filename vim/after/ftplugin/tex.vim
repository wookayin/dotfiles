setlocal expandtab

" (La)TeX keywords, use ':' as well.
" However, the iskeyword setting is overriden in vim's global 'syntax/tex.vim',
" so we use a workaround, as specified, to set the variable 'g:tex_isk'.
" setlocal iskeyword+=:
let g:tex_isk='48-57,_,a-z,A-Z,192-255,:'

if !filereadable('Makefile')
    "let &l:makeprg = "(latexmk -pdf -pdflatex=\"xelatex -halt-on-error -interaction=nonstopmode\" %:r && latexmk -c %:r)"
    let &l:makeprg = "xelatex -recorder -halt-on-error -interaction=nonstopmode %:r"
endif

" configure default fold level
setlocal foldlevel=1
