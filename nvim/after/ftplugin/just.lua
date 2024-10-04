local setlocal = vim.opt_local
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2
setlocal.expandtab = true

-- auto-indent is lacking: NoahTheDuke/vim-just#19
vim.cmd.source "$VIMRUNTIME/indent/make.vim"
vim.b.undo_indent = nil
vim.opt_local.indentexpr = 'GetMakeIndent()'
