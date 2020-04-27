runtime autoload/plug_addon.vim

let s:darwin = has('mac')

" Plug buffers appear in a new tab
let g:plug_window = '-tabnew'

" for neovim plugins (rplugin)
if has('nvim')
  function! DoRemote(arg)
    UpdateRemotePlugins
  endfunction
endif

let s:_python3_version = ''
function! s:python3_version()
  if has('nvim')           | return g:python3_host_version
  elseif has('python3')
    if empty(s:_python3_version)
      let s:_python3_version = join(py3eval('sys.version_info'), ".")
    endif
    return s:_python3_version
  else | return ''
  endif
endfunction

"==============================================
call plug#begin('~/.vim/plugged')
"==============================================

" General and Behaviour
Plug 'flazz/vim-colorschemes'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tweekmonster/helpful.vim', { 'on' : ['HelpfulVersion'] }
if has('patch-7.4.1154')  " requires v:false
  Plug 'embear/vim-localvimrc'
endif

" Integration and Interfaces
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all --no-update-rc' }
Plug 'junegunn/fzf.vim'
Plug 'wookayin/fzf-ripgrep.vim'
if has('nvim-0.4.0')
  Plug 'liuchengxu/vim-clap'
  Plug 'voldikss/vim-floaterm'
endif
if has('nvim-0.4.0') || has('popup')
  Plug 'skywind3000/vim-quickui'
endif
Plug 'ervandew/supertab'
Plug 'scrooloose/nerdtree'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'Xuyuanp/nerdtree-git-plugin'
if executable('tree')
  Plug 'mhinz/vim-tree'
endif
Plug 'vim-voom/VOoM', { 'on' : ['Voom', 'VoomToggle'] }
Plug 'tpope/vim-dispatch', { 'tag' : 'v1.1' }
if has('nvim') || v:version >= 800
  Plug 'neomake/neomake'
endif
Plug 'tpope/vim-tbone'
Plug 'szw/vim-maximizer'    " zoom and unzoom!
Plug 'junegunn/goyo.vim'
Plug 'christoomey/vim-tmux-navigator'
if !has('nvim')
  " focus-events work by default in Neovim (see issue #1), so
  " this plugin is not needed for neovim. Don't reserve <F24>
  Plug 'tmux-plugins/vim-tmux-focus-events'
        \ | ForcePlugURI 'vim-tmux-focus-events'
endif
Plug 'tpope/vim-fugitive'
Plug 'junegunn/gv.vim'
Plug 'airblade/vim-gitgutter'
if has('nvim-0.4.0') && exists('*nvim_open_win')
  " git blame with floating window (requires nvim 0.4.0+)
  Plug 'rhysd/git-messenger.vim'
endif
Plug 'majutsushi/tagbar'
Plug 'rking/ag.vim'
Plug 'kshenoy/vim-signature'
Plug 'junegunn/vim-easy-align'
Plug 'Yggdroot/indentLine'

" Utilities
Plug 'junegunn/vim-emoji'
Plug 'cocopon/colorswatch.vim', { 'on' : ['ColorSwatchGenerate'] }
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'Lokaltog/vim-easymotion'
Plug 'unblevable/quick-scope'
Plug 'haya14busa/vim-asterisk'
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-fuzzy.vim'
Plug 't9md/vim-quickhl'
if executable('diff') && has('patch-7.4.1685')
  Plug 'machakann/vim-highlightedundo'
endif

if v:version >= 800 || v:version == 704 && has('patch786')
  " requires vim 7.4.786+ (see issue #23)
  Plug 'machakann/vim-highlightedyank'
endif

Plug 'scrooloose/nerdcommenter'
Plug 'junegunn/vim-peekaboo'
Plug 'sjl/gundo.vim'
if has('python3') && s:python3_version() >= '3.5'
  Plug 'SirVer/ultisnips'
endif
Plug 'vim-scripts/matchit.zip'
Plug 'tomtom/tlib_vim'
Plug 'junegunn/vader.vim'
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tpope/vim-eunuch'
Plug 'rizzatti/dash.vim',   { 'on': 'Dash' }
Plug 'wookayin/vim-typora', { 'on': 'Typora' }
Plug 'liuchengxu/vim-which-key', { 'on': ['WhichKey', 'WhichKey!'] }

" Syntax, Completion, Coding stuffs
Plug 'editorconfig/editorconfig-vim'

Plug 'sheerun/vim-polyglot'
Plug 'tmux-plugins/vim-tmux'

Plug 'klen/python-mode', { 'branch': 'develop' } |
      \ Plug 'wookayin/vim-python-enhanced-syntax'
Plug 'davidhalter/jedi-vim'
if has('nvim') && s:python3_version() >= '3.5'
  Plug 'numirias/semshi', { 'do': function('DoRemote') }
  Plug 'stsewd/isort.nvim', { 'do': function('DoRemote') }
endif
if has('python3') && s:python3_version() >= '3.5'
  Plug 'wookayin/vim-autoimport'
endif

Plug 'artur-shaik/vim-javacomplete2'

Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
"Plug 'LaTeX-Box-Team/LaTeX-Box'
Plug 'lervag/vimtex', { 'for' : ['tex', 'plaintex'] }
Plug 'machakann/vim-Verdin', { 'for': ['vim'] }   " vimscript omnifunc
Plug 'gisraptor/vim-lilypond-integrator'
Plug 'tfnico/vim-gradle'
Plug 'Tyilo/applescript.vim'
Plug 'rdolgushin/groovy.vim'

if has('nvim')
  Plug 'Shougo/echodoc.vim'
endif

Plug 'xolox/vim-misc'
Plug 'xolox/vim-lua-ftplugin', { 'for' : ['lua'] }


" Completion engine for neovim (deoplete or language server)
" Requires python 3.6.1+
if has('nvim') && s:python3_version() >= '3.6.1'
  Plug 'Shougo/deoplete.nvim', { 'do': function('DoRemote') }
  Plug 'zchee/deoplete-jedi'    " Python
  Plug 'zchee/deoplete-clang'   " C/C++
  Plug 'zchee/deoplete-zsh', { 'for': ['zsh'] }     " zsh
endif

" Asynchronous Lint Engine (ALE)
if has('nvim') || v:version >= 800
  Plug 'w0rp/ale'
endif

" [coc.nvim] Language-server support (neovim and vim8)
" Activated if the following conditions are met:
"    (i) Proper neovim/vim8 version and python3
"    (ii) 'node' and 'npm' are installed
"    (iii) Directory ~/.config/coc exists
function! s:configure_coc_nvim()
  if (has('nvim') || v:version >= 800) &&
        \ executable('npm') && executable('python3') &&
        \ isdirectory(expand("\~/.config/coc/"))
  else | return | endif   " do nothing if conditions are not met

  if has('nvim') && !has('nvim-0.3.1')
    autocmd VimEnter * echohl WarningMsg | echom
          \ 'WARNING: Neovim 0.3.1+ or Vim 8.0+ is required for coc.nvim. '
          \ . '(Try: dotfiles install neovim)' | echohl None
    return
  endif

  let node_version = system('node --version')
  if plug_addon#version_lessthan(node_version, 'v8.10')
    autocmd VimEnter * echohl WarningMsg | echom
          \ 'WARNING: Node v8.10.0+ is required for coc.nvim. '
          \ . '(Try: dotfiles install node)' | echohl None
    return
  endif

  "Plug 'neoclide/coc.nvim', {'do': function('coc#util#install') }   " from source
  Plug 'neoclide/coc.nvim', {'branch': 'release'}                    " released binary
  Plug 'neoclide/jsonc.vim'
  if has('nvim-0.4.0')
    Plug 'antoinemadec/coc-fzf'
  endif

  " coc supercedes deoplete and supertab
  UnPlug 'Shougo/deoplete.nvim'
  UnPlug 'davidhalter/jedi-vim'
  UnPlug 'ervandew/supertab'         " Custom <TAB> mapping supercedes supertab

  let s:floating_available = exists('*nvim_open_win') &&
        \ (exists('##MenuPopupChanged') || exists('##CompleteChanged'))
  if s:floating_available
    " disable vim-which-key if floating windows are used (have some conflicts)
    UnPlug 'liuchengxu/vim-which-key'
  endif

  " automatically install CocExtensions by default
  let g:coc_global_extensions = [
        \ 'coc-json', 'coc-highlight', 'coc-snippets', 'coc-explorer',
        \ 'coc-python', 'coc-vimlsp'
        \ ]

endfunction
call s:configure_coc_nvim()


" Additional, optional local plugins
if filereadable(expand("\~/.vim/plugins.local.vim"))
  source \~/.vim/plugins.local.vim
endif

call plug#end()

delcom UnPlug
delcom ForcePlugURI

" vim: set ts=2 sts=2 sw=2:
