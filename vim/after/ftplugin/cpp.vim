" options
" =======
setlocal completeopt=longest,menuone,preview


" cpp-specific Keymaps
" ====================

" Show <Quickfix List> buffer at the right splitted vertically
if isdirectory(expand("~/.vim/plugged/vim-dispatch"))
    noremap <F6> <ESC>:cclose<CR>:TheCopen<CR>:wincmd L<CR>:60wincmd \|<CR>:wincmd h<CR>
else
    noremap <F6> <ESC>:cclose<CR>:vertical 60copen<CR>:wincmd h<CR>
endif

" Automatic makeprg generation (regarding %:r.in, %r.ans)
if !filereadable('Makefile')
    let b:sourcefile = expand("%")
    let b:basename = expand("%:r")
    let b:input_file = ""
    let b:answer_file = ""
    let b:output_file = b:basename . ".out"
    if filereadable(b:basename . ".in")  | let b:input_file = b:basename . ".in" | endif
    if filereadable(b:basename . ".ans") | let b:answer_file = b:basename . ".ans" | endif

    let b:extraflag = ""
    let s:gccver = system("g++ --version | grep '^g++' | sed 's/^.* //g'")
    if s:gccver >= "4.9.0" | let b:extraflag = b:extraflag . " -fdiagnostics-color=never" | endif

    let b:makeprg_compile = printf("g++ -g -Wall --std=c++11 -O2 %s -o %s %s",
                \ shellescape(expand("%")), shellescape(b:basename), b:extraflag)
    let b:makeprg_run     = printf("time ./%s", shellescape(b:basename))
    if !empty(b:input_file)  | let b:makeprg_run .= printf(" < %s", shellescape(b:input_file)) | endif
    if !empty(b:answer_file) | let b:makeprg_run .= printf(" | tee %s && diff -wu %s %s",
                \ shellescape(b:output_file), shellescape(b:output_file), shellescape(b:answer_file)) | endif

    let &l:makeprg = "(" . join([b:makeprg_compile, b:makeprg_run], " && ") . ")"
endif
