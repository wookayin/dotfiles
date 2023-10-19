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

inoremap <buffer> <C-b>  <cmd>Build<CR>
