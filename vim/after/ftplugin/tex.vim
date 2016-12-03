setlocal expandtab

" (La)TeX keywords, use ':' as well.
" However, the iskeyword setting is overriden in vim's global 'syntax/tex.vim',
" so we use a workaround, as specified, to set the variable 'g:tex_isk'.
" setlocal iskeyword+=:
let g:tex_isk='48-57,_,a-z,A-Z,192-255,:'


" configure default fold level
setlocal foldlevel=1



" Make and build support
" ======================

" default makeprg
if !filereadable('Makefile')
    "let &l:makeprg = "(latexmk -pdf -pdflatex=\"xelatex -halt-on-error -interaction=nonstopmode\" %:r && latexmk -c %:r)"
    let &l:makeprg = "xelatex -recorder -halt-on-error -interaction=nonstopmode %:r"
endif

" If using neomake, run callbacks after make is done
function! s:OnNeomakeFinished(context)
    " the buffer on which Neomake was invoked
    let l:bufnr = get(a:context, 'bufnr', -1)

    if l:bufnr != -1 && bufexists(l:bufnr)
        " backup the current buffer (may different)
        let l:curbuf = bufnr('%')

        " call VimtexView on the target buffer!!
        silent execute printf("%d,%dbufdo!", l:bufnr, l:bufnr) 'VimtexView'

        " re-jump to the current buffer
        if l:curbuf != l:bufnr
            silent execute 'buffer' l:curbuf
        endif
    else
        " bufnr not available, just call VimtexView
        " (might cause an error on other buffer than tex buffers)
        " TODO it should be fixed after @neomake/neomake#807 is done
        VimtexView
    endif

endfunction

augroup tex_neomake_callback
    au!
    autocmd User NeomakeFinished call s:OnNeomakeFinished(g:neomake_hook_context)
augroup END
