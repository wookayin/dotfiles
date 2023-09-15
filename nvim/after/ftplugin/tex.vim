setlocal expandtab

" (La)TeX keywords, use ':' as well.
" However, the iskeyword setting is overriden in vim's global 'syntax/tex.vim',
" so we use a workaround, as specified, to set the variable 'g:tex_isk'.
setlocal iskeyword+=:,-
let g:tex_isk='48-57,_,a-z,A-Z,192-255,:,-'

" configure default fold level
if !get(g:, 'has_folding_ufo')
    setlocal foldlevel=1
endif

" tex-specific settings
setlocal colorcolumn=100

" Do not use conceal for LaTeX (e.g. indentLine)
setlocal conceallevel=0

" Use spell checking
setlocal spell

" More keymaps
" ------------

" wrap current word or selection with textbf/textit (need surround.vim)
nmap <buffer> <leader>b ysiw}i\textbf<ESC>
nmap <buffer> <leader>i ysiw}i\textit<ESC>
nmap <buffer> <leader>u ysiw}i\underline<ESC>
vmap <buffer> <leader>b S}i\textbf<ESC>
vmap <buffer> <leader>i S}i\textit<ESC>
vmap <buffer> <leader>u S}i\underline<ESC>

" easy-align of align/tables {{
" (with block)
vmap <buffer> <leader>A ga*&
" (inside current environment 'vie')
nmap <buffer> <leader>A viega*&
" }}

" Make and build support
" ======================

inoremap <buffer> <C-b>  <cmd>Build<CR>

" default makeprg
if filereadable('Makefile')
    let &l:makeprg = 'make'
elseif filereadable(expand("%:p:h") . "/Makefile")
    let &l:makeprg = 'make'
    :CD      " auto-CWD to the file's basepath (see ~/.vimrc)
else
    let &l:makeprg = '(latexmk -pdf -pdflatex="pdflatex -halt-on-error -interaction=nonstopmode -file-line-error -synctex=1" "%:r" && latexmk -c "%:r")'
    "let &l:makeprg = 'xelatex -recorder -halt-on-error -interaction=nonstopmode -file-line-error -synctex=1 "%:r"'
endif

" If using neomake, run callbacks after make is done
function! s:OnNeomakeFinished(context)
    if ! exists(':VimtexView')
      return
    endif
    if ! get(b:, 'neomake_vimtexview_enabled', 1)
      " disabled temporarily, no VimtexView
      return
    endif

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

command! -buffer -nargs=0 VimtexViewDisable     let b:neomake_vimtexview_enabled = 0
command! -buffer -nargs=0 VimtexViewEnable      let b:neomake_vimtexview_enabled = 1
