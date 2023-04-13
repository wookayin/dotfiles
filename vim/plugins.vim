"-------------
" plugins.vim
"-------------

" Utilities and Helpers {{{

runtime autoload/plug_addon.vim

let s:darwin = has('mac')

" Plug buffers appear in a new tab
let g:plug_window = '-tabnew'

" for neovim plugins (rplugin)
if has('nvim')
  function! UpdateRemote(arg)
    if has_key(g:, 'did_plug_UpdateRemote') | return | endif
    let g:did_plug_UpdateDoRemote = 1
    UpdateRemotePlugins
  endfunction
endif

" python version check
let s:has_py35 = has('python3') && py3eval('sys.version_info >= (3, 5)')

" Detect (neo)vim features
let s:floating_available = exists('*nvim_open_win') &&
      \ (exists('##MenuPopupChanged') || exists('##CompleteChanged'))
" }}}

"==============================================
let $VIMPLUG='~/.vim/plugged'
call plug#begin($VIMPLUG)
"==============================================

" General Plugins
" -------------------------------------
Plug 'flazz/vim-colorschemes'
Plug 'embear/vim-localvimrc', PlugCond(has('patch-7.4.1154'))  " requires v:false
Plug 'tweekmonster/helpful.vim', { 'on' : ['HelpfulVersion'] }
Plug 'dstein64/vim-startuptime', { 'on': ['StartupTime'] }

" Vim Interfaces
" -------------------------------------
if has('nvim')
  " Status line: use lualine.nvim (fork)
  Plug 'nvim-lualine/lualine.nvim'
  ForcePlugURI 'lualine.nvim'
else
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
endif

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all --no-update-rc' }
Plug 'junegunn/fzf.vim'
Plug 'wookayin/fzf-ripgrep.vim'
if has('nvim') || has('popup')
  Plug 'voldikss/vim-floaterm'
  Plug 'skywind3000/vim-quickui'
endif
if exists('##TermOpen') || exists('##TerminalOpen')
  Plug 'mg979/vim-xtabline'
endif

let g:_nerdtree_lazy_events = ['NERDTree', 'NERDTreeToggle', 'NERDTreeTabsToggle', '<Plug>NERDTreeTabsToggle']
Plug 'scrooloose/nerdtree', { 'on': g:_nerdtree_lazy_events }
Plug 'jistr/vim-nerdtree-tabs', { 'on': g:_nerdtree_lazy_events }
Plug 'Xuyuanp/nerdtree-git-plugin'

Plug 'vim-voom/VOoM', { 'on' : ['Voom', 'VoomToggle'] }
if has('nvim')
   Plug 'kevinhwang91/nvim-bqf'
endif
if has('nvim') || v:version >= 800
  Plug 'neomake/neomake'
  Plug 'skywind3000/asyncrun.vim'
endif
Plug 'vim-scripts/errormarker.vim'
if has('nvim')
  Plug 'gelguy/wilder.nvim', { 'do': function('UpdateRemote') }
  Plug 'romgrk/fzy-lua-native'
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
Plug 'rbong/vim-flog'
if has('nvim')
  " see GH-768
  Plug 'lewis6991/gitsigns.nvim', PinIf(!has('nvim-0.8.0'), {'commit': '76b71f74'})
else
  Plug 'airblade/vim-gitgutter'
endif
if has('nvim')
  Plug 'sindrets/diffview.nvim'
  Plug 'rhysd/git-messenger.vim'
endif
Plug 'majutsushi/tagbar'
Plug 'rking/ag.vim'
Plug 'kshenoy/vim-signature'
Plug 'junegunn/vim-easy-align'
if has('nvim')
  Plug 'lukas-reineke/indent-blankline.nvim'
else
  Plug 'Yggdroot/indentLine'
endif
if exists('##WinScrolled')
  Plug 'dstein64/nvim-scrollview'
endif

" Advanced Folding
if has('nvim')
  Plug 'kevinhwang91/nvim-ufo'
  Plug 'kevinhwang91/promise-async'
end

" Miscellanious Utilities
" -------------------------------------
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


Plug 'scrooloose/nerdcommenter'
Plug 'junegunn/vim-peekaboo'
Plug 'sjl/gundo.vim'
if has('python3') && s:has_py35
  Plug 'SirVer/ultisnips'
endif
Plug 'vim-scripts/matchit.zip'
Plug 'tomtom/tlib_vim'
Plug 'junegunn/vader.vim'
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'tpope/vim-eunuch'
Plug 'wookayin/vim-typora', { 'on': 'Typora' }
if has('nvim')
  Plug 'folke/which-key.nvim'
endif

if s:darwin && isdirectory('/Applications/Dash.app')
  if has('nvim')
    Plug 'mrjones2014/dash.nvim', { 'do': 'make install',
          \ 'on': ['Dash', 'DashWord'] }
  else
    Plug 'rizzatti/dash.vim',   { 'on': 'Dash' }
  endif
endif

if has('nvim')
  " Some lua-powered plugins for UI
  Plug 'nvim-lua/plenary.nvim'
  Plug 'rcarriga/nvim-notify'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'nvim-neo-tree/neo-tree.nvim', {'branch': 'main'}
  Plug 'MunifTanjim/nui.nvim'
  Plug 'stevearc/dressing.nvim'

  Plug 'nvim-telescope/telescope.nvim'
endif

" Treesitter (see ~/.config/nvim/lua/config/treesitter.lua)
if has('nvim')
  function! TSUpdate(arg) abort
    if luaeval('pcall(require, "nvim-treesitter")')
      TSUpdate
    endif
  endfunction

  let g:_plug_ts_config = {'do': function('TSUpdate')}
  if !has('nvim-0.8')
    " Since 42ab95d5, nvim 0.8.0+ is required
    let g:_plug_ts_config['commit'] = '4cccb6f4'
  endif
  Plug 'nvim-treesitter/nvim-treesitter', g:_plug_ts_config
  Plug 'nvim-treesitter/playground', {'as': 'nvim-treesitter-playground'}

  Plug 'SmiteshP/nvim-gps'
endif

" Test integration
if has('nvim')
  Plug 'nvim-neotest/neotest'
  Plug 'antoinemadec/FixCursorHold.nvim'

  Plug 'nvim-neotest/neotest-python'
  Plug 'nvim-neotest/neotest-plenary'
endif

" Syntax, Completion, Language Servers, etc.
" ------------------------------------------

" Neovim LSP related plugins.
" See also for more config: ~/.config/nvim/lua/config/lsp.lua
if has('nvim')
  Plug 'neovim/nvim-lspconfig'
  Plug 'williamboman/mason.nvim'
  Plug 'williamboman/mason-lspconfig.nvim'
  Plug 'folke/neodev.nvim'

  Plug 'hrsh7th/nvim-cmp', {'commit': '4c05626'}
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-path'
  Plug 'quangnguyen30192/cmp-nvim-ultisnips'

  Plug 'ray-x/lsp_signature.nvim'
  Plug 'nvim-lua/lsp-status.nvim'
  Plug 'j-hui/fidget.nvim'
  Plug 'folke/trouble.nvim'
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'onsails/lspkind-nvim'

  Plug 'jose-elias-alvarez/null-ls.nvim'
endif

" Other language-specific plugins (supplementary and orthogonal to LSP)
" ---------------------------------------------------------------------
Plug 'editorconfig/editorconfig-vim'

if has('python3')
  Plug 'klen/python-mode', { 'branch': 'develop' }
  Plug 'wookayin/vim-python-enhanced-syntax'
endif

" polyglot: cannot use latest version (see GH-608, GH-613)
Plug 'sheerun/vim-polyglot', {'tag': 'v4.2.1'}
Plug 'tmux-plugins/vim-tmux'
Plug 'fladson/vim-kitty', { 'for': ['kitty'] }

if has('nvim') && s:has_py35
  " Semshi is no longer being maintained. Use my own fork
  Plug 'wookayin/semshi', { 'do': function('UpdateRemote') }
  ForcePlugURI 'semshi'
  Plug 'stsewd/isort.nvim', { 'do': function('UpdateRemote') }
  Plug 'wookayin/vim-autoimport'
endif

Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'lervag/vimtex', { 'for' : ['tex', 'plaintex'] }
Plug 'machakann/vim-Verdin', { 'for': ['vim'] }   " vimscript omnifunc
Plug 'gisraptor/vim-lilypond-integrator'
Plug 'tfnico/vim-gradle'
Plug 'Tyilo/applescript.vim'
Plug 'rdolgushin/groovy.vim'


" =======================================================
" Additional, optional local plugins
" =======================================================
if filereadable(expand("\~/.vim/plugins.local.vim"))
  source \~/.vim/plugins.local.vim
endif

call plug#end()

" Cleanup {{{
delcom UnPlug
delcom ForcePlugURI
silent delfunction PlugCond
silent delfunction PinIf
silent unlet g:_nerdtree_lazy_events
" }}}


" Automatically install missing plugins on startup
function! s:plug_missing(plug)
  return !isdirectory(a:plug.dir) && !empty(get(a:plug, "uri"))
endfunction
let g:plugs_missing_on_startup = filter(values(g:plugs), 's:plug_missing(v:val)')
if len(g:plugs_missing_on_startup) > 0
  PlugInstall --sync | q
endif

" PlugInject: dynamically install and load plugins after startup
command! -nargs=1 PlugInject       Plug <args> | call s:plug_install(<args>)
function! s:plug_install(name, ...) abort
  let l:name = fnamemodify(a:name, ':t')
  if a:0 >= 1 && has_key(a:1, 'as')
    let l:name = a:1['as']
  endif
  if s:plug_missing(g:plugs[l:name])
    exec printf('PlugInstall %s --sync | if &ft == "vim-plug" | q | endif', l:name)
  else
    call plug#load(l:name)
    echohl Special | echom "Loaded plugin: " . l:name | echohl NONE
  endif
endfunction


" vim: set ts=2 sts=2 sw=2 foldenable foldmethod=marker:
