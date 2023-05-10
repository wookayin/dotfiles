"-------------
" plugins.vim
" DEPRECATED: This is no longer used in neovim, only for vanilla vim.
" vim: set ts=2 sts=2 sw=2 foldenable foldmethod=marker:
"-------------

if has('nvim')
  lua vim.notify("plugins.vim is no longer is used in neovim.", "error", { title = "vim/plugins.vim" })
  finish
endif

" Plug buffers appear in a new tab
let g:plug_window = '-tabnew'

"==============================================
let $VIMPLUG='~/.vim/plugged'
call plug#begin($VIMPLUG)
"==============================================

Plug 'flazz/vim-colorschemes'
Plug 'tweekmonster/helpful.vim', { 'on' : ['HelpfulVersion'] }
Plug 'dstein64/vim-startuptime', { 'on': ['StartupTime'] }

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all --no-update-rc' }
Plug 'junegunn/fzf.vim'
Plug 'mg979/vim-xtabline'

Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'tpope/vim-fugitive'

Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'haya14busa/vim-asterisk'
Plug 'tpope/vim-commentary'
Plug 'sheerun/vim-polyglot', {'tag': 'v4.2.1'}
Plug 'tmux-plugins/vim-tmux'
Plug 'fladson/vim-kitty', { 'for': ['kitty'] }

" =======================================================
" Additional, optional local plugins
" =======================================================
if filereadable(expand("\~/.vim/plugins.local.vim"))
  source \~/.vim/plugins.local.vim
endif

call plug#end()

" Automatically install missing plugins on startup
function! s:plug_missing(plug)
  return !isdirectory(a:plug.dir) && !empty(get(a:plug, "uri"))
endfunction
let g:plugs_missing_on_startup = filter(values(g:plugs), 's:plug_missing(v:val)')
if len(g:plugs_missing_on_startup) > 0
  PlugInstall --sync | q
endif
