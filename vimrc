" wookayin's vimrc file
" https://github.com/wookayin/vim-config

"""""""""""""""""""""""""""
" 1. General Settings
"""""""""""""""""""""""""""

syntax on
set nocompatible

" load plugins with pathogen/vundle
try
	runtime bundle/pathogen/autoload/pathogen.vim
	call pathogen#infect()
catch
endtry

" basic displays and colors
" (for detailed color settings, see section 3)
colorscheme evening
set bg=dark
set number					" show line numbers
set ruler
"set t_Co=256
"colorscheme xoria256

" input settings
set bs=indent,eol,start		" allow backspaces over everything
set autoindent
set smartindent
set pastetoggle=<F8>

set wrap
set textwidth=0				" disable automatic line breaking 
set cursorline

" tab settings
set tabstop=4
set shiftwidth=4
set softtabstop=4

" tab navigation
set showtabline=2			" always show tab pannel

set scrolloff=3

" search
set ignorecase				" case-insensitive by default
set smartcase				" case-sensitive if keyword contains both uppercase and lowercase
set incsearch
set hlsearch

" wildmenu settings
set wildmenu
set wildmode=list:longest,full
set wildignore=*.swp,*.swo,*.class

" status line
set statusline=%1*%{winnr()}\ %*%<\ %f\ %h%m%r%=%l,%c%V\ (%P)
set laststatus=2			" show anytime

" mouse behaviour
set mouse=nvc
set ttymouse=xterm2

" encoding and line ending settings
set encoding=utf-8
set fileencodings=utf-8,cp949,latin1
set fileformats=unix,dos

" miscellanious
set showmode
set showcmd

set visualbell
set history=1000
set undolevels=1000
set lazyredraw				" no redrawing during macro execution

set mps+=<:>


"""""""""""""""""""""""""""
" 2. Key Mappings
"""""""""""""""""""""""""""

" navigation key mapping
map k gk
map j gj
map <up> gk
map <down> gj
imap <up> <c-o>gk
imap <down> <c-o>gj

" window navigation
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

" do not exit from visual mode when shifting
" (gv : select the preivous area)
vnoremap < <gv		
vnoremap > >gv

" [F5] Make
map <F5> <ESC>:w<CR>:make!<CR>

" [F4] Next Error [Shift+F4] Previous Error
map <F4> <ESC>:cn<CR>
map [26~ <ESC>:cp<CR>

" [F2] save
imap <F2> <ESC>:w<CR>
map <F2> <ESC><ESC>:w<CR>


"""""""""""""""""""""""""""
" 3. Highlight and Syntax
"""""""""""""""""""""""""""

" highlight
highlight LineNr ctermfg=black ctermbg=Gray
highlight StatusLine ctermfg=LightGreen

highlight Comment ctermfg=darkgreen
au FileType c,cpp,latex,tex highlight Comment ctermfg=cyan

" IDE settings
filetype plugin on
filetype indent on

"""""""""""""""""""""""""""
" 4. GUI Options
"""""""""""""""""""""""""""

" gui settings
if has("gui_running")
	language mes en
	set langmenu=none
	set guioptions-=T
	set guioptions-=m 
	set encoding=utf8
	set guifont=Consolas:h11:cANSI
	set guifontwide=GulimChe:h12:cDEFAULT
endif

