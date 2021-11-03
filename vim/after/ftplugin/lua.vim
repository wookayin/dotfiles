" Use tab size of 2.
setlocal ts=2 sts=2 sw=2

" <F5> action: source it, if a (neo)vim config
if expand("%:p") =~ "nvim/lua/config/"
  noremap <buffer> <F5>
        \ <cmd>source %<CR><cmd>call VimNotify("Sourced " . bufname('%'))<CR>
endif
