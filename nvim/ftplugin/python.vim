" This ftplugin executes before $VIMRUNTIME/ftplugin/python.vim,
" ensures g:python3_host_prog is set before calling has('python')
" from the builtin ftplugin.
lua require("config.pynvim")

" Oops, were you looking for $DOTVIM/after/ftplugin/python.vim ?
