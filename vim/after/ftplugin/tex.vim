setlocal expandtab

" (La)TeX keywords, use ':' as well.
" However, the iskeyword setting is overriden in vim's global 'syntax/tex.vim',
" so we use a workaround, as specified, to set the variable 'g:tex_isk'.
" setlocal iskeyword+=:
let g:tex_isk='48-57,_,a-z,A-Z,192-255,:'


" configure default fold level
setlocal foldlevel=1

" More keymaps
" ------------

" wrap current word or selection with textbf/textit (need surround.vim)
nmap <leader>b ysiw}i\textbf<ESC>
nmap <leader>i ysiw}i\textit<ESC>
nmap <leader>u ysiw}i\underline<ESC>
vmap <leader>b S}i\textbf<ESC>
vmap <leader>i S}i\textit<ESC>
vmap <leader>u S}i\underline<ESC>


" Make and build support
" ======================

" default makeprg
if !filereadable('Makefile')
    "let &l:makeprg = '(latexmk -pdf -pdflatex=\"xelatex -halt-on-error -interaction=nonstopmode\" %:r && latexmk -c "%:r")'
    let &l:makeprg = 'xelatex -recorder -halt-on-error -interaction=nonstopmode -synctex=1 "%:r"'
endif

" If using neomake, run callbacks after make is done
function! s:OnNeomakeFinished(context)
    let l:context = g:neomake_hook_context
    " the buffer on which Neomake was invoked
    let l:bufnr = get(l:context['options'], 'bufnr', -1)

    if l:bufnr != -1 && bufexists(l:bufnr)
        " backup the current buffer or window (may different to the invoker)
        let l:cur_winid = win_getid()
        let l:target_winid = bufwinid(l:bufnr)

        if l:target_winid != -1
            " call VimtexView on the target window!
            call win_gotoid(l:target_winid)
            VimtexView

            " jump back to the current buffer
            if l:cur_winid != l:target_winid
                call win_gotoid(l:cur_winid)
            endif
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
