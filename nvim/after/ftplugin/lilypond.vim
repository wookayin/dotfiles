" Lilypond filetype plugin
" overrides vim-lilypond-integrator plugin

" Do not use lilypond.vim's ftplugin mappings
" see $VIMPLUG/vim-polyglot/ftplugin/lilypond.vim
silent! unmap <buffer> <F5>
silent! unmap <buffer> <F6>

map <buffer> <F4> :Dispatch lilypond %; timidity %:r.midi<CR>

set makeprg=lilypond\ %
