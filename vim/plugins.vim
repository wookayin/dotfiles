call plug#begin('~/.vim/plugged')

" General and Behaviour
Plug 'flazz/vim-colorschemes'
Plug 'bling/vim-airline'
Plug 'mhinz/vim-startify'

" Integration and Interfaces
Plug 'junegunn/fzf', { 'dir': '~/.fzf' }
Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tpope/vim-dispatch', { 'tag' : 'v1.1' }
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'majutsushi/tagbar'
Plug 'kien/ctrlp.vim'
Plug 'vim-scripts/ctrlp-z'
Plug 'rking/ag.vim'
Plug 'kshenoy/vim-signature'

" Utilities
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'rhysd/clever-f.vim'
Plug 'Lokaltog/vim-easymotion'
Plug 'scrooloose/nerdcommenter'
Plug 'sjl/gundo.vim'
Plug 'SirVer/ultisnips'
Plug 'vim-scripts/matchit.zip'
Plug 'tomtom/tlib_vim'
Plug 'MarcWeber/vim-addon-mw-utils'

" Syntax, Completion, Coding stuffs
Plug 'rust-lang/rust.vim'
Plug 'vim-scripts/nginx.vim'
Plug 'vim-ruby/vim-ruby'
Plug 'klen/python-mode'
Plug 'davidhalter/jedi-vim'
Plug 'pangloss/vim-javascript'
Plug 'briancollins/vim-jst'
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'LaTeX-Box-Team/LaTeX-Box'

call plug#end()
