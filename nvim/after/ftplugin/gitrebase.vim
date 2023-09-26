" ftplugin/gitrebase

" gitrebase keymaps with repeat(.) support, requires fugitive
if exists("*FugitiveGitDir")
  function! s:define_cmd_mapping(cmd) abort
    let cmd = 'nnoremap <buffer> ' . printf('<Plug>(gitrebase-cmd-%s)', a:cmd) . ' '

    let cmd = cmd . '<cmd>let b:_cursor = getpos(".")<CR>'
    let cmd = cmd . printf('<cmd>%s<CR>', a:cmd)
    let cmd = cmd . '<cmd>call setpos(".", b:_cursor + [b:_cursor[2]])<CR>'

    let cmd = cmd . printf('<cmd>silent! call repeat#set("\<Plug>(gitrebase-cmd-%s)")<CR>', a:cmd)
    exec cmd
  endfunction
  for cmd in ["Edit", "Reword", "Squash", "Fixup", "Drop"]
    call s:define_cmd_mapping(cmd)
  endfor

  nmap <buffer> <nowait> <leader>e       <Plug>(gitrebase-cmd-Edit)
  nmap <buffer> <nowait> <leader>r       <Plug>(gitrebase-cmd-Reword)
  nmap <buffer> <nowait> <leader>s       <Plug>(gitrebase-cmd-Squash)
  nmap <buffer> <nowait> <leader>f       <Plug>(gitrebase-cmd-Fixup)
  nmap <buffer> <nowait> <leader>d       <Plug>(gitrebase-cmd-Drop)

  nmap <buffer> <nowait> <leader>j       <cmd>move .+1<CR>
  nmap <buffer> <nowait> <leader>k       <cmd>move .-2<CR>
  nmap <buffer> <nowait> <M-j>           <cmd>move .+1<CR>
  nmap <buffer> <nowait> <M-k>           <cmd>move .-2<CR>
endif

" treesitter highlight
lua << EOF
require("config.treesitter").ensure_parsers_installed { "git_rebase", "diff" }
require("config.treesitter").setup_highlight("git_rebase")
EOF
