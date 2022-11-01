" Use tab size of 2.
setlocal ts=2 sts=2 sw=2

" <F5> or :Make ==> source it, if a (neo)vim config
if expand("%:p") =~ "nvim/lua/config/"
  command! -buffer -bar  Build   w | source % | call VimNotify("Sourced " . bufname('%'))
endif

" Make goto-file (gf, ]f) detect lua config files.
setlocal path+=~/.dotfiles/nvim/lua
