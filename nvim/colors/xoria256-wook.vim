" Vim color file
"
" Name:            xoria256-wook.vim
" Original Author: Dmitriy Y. Zotikov <xio@unground.org>
"
" This is a colorscheme based on xoria256 but with more customization added.

" $VIMPLUG/vim-colorschemes/colors/xoria256.vim
runtime colors/xoria256.vim

let g:colors_name = "xoria256-wook"

" Explicitly list and define highlights for default groups that are lacking in
" the base colorscheme; make the colorscheme look as similar as with the legacy vim
" colorscheme prior to the new default colorscheme in 0.10 (see neovim/neovim#26378)
" Note: this list of compat fix might not be exhaustive.
" (see $VIMRUNTIME/colors/vim.vim) {{{
hi! link  String        Constant
hi! link  Function      Identifier
hi!       MoreMsg       ctermfg=DarkGreen  ctermbg=NONE gui=bold guifg=SeaGreen guibg=NONE
hi!       Question      ctermfg=LightGreen ctermbg=NONE gui=bold guifg=Green    guibg=NONE
hi!       WarningMsg    ctermfg=LightRed   ctermbg=NONE gui=NONE guifg=Red      guibg=NONE
hi! link  WinSeparator  VertSplit
hi! link  FloatBorder   WinSeparator
hi! link  QuickFixLine  Search
" }}}

" override more customized colors
highlight StatusLine    ctermfg=LightGreen
highlight ColorColumn   ctermbg=52 guibg=#5f0000

highlight LineNr        ctermfg=248 ctermbg=233   guifg=#a8a8a8 guibg=#121212
highlight CursorLineNr  cterm=none gui=bold guifg=Yellow
highlight SignColumn    ctermfg=248 ctermbg=233   guifg=#a8a8a8 guibg=#121212
highlight VertSplit     ctermfg=246 ctermbg=NONE  guifg=#6d747f guibg=NONE

" gitgutter sign column (see afa4f2dd)
"  guibg=<X> and ctermbg=<Y> should match that of SignColumn
highlight GitGutterAdd    guifg=#009900 guibg=#121212 ctermfg=2 ctermbg=233
highlight GitGutterChange guifg=#bbbb00 guibg=#121212 ctermfg=3 ctermbg=233
highlight GitGutterDelete guifg=#ff2222 guibg=#121212 ctermfg=1 ctermbg=233

hi link GitSignsAdd     GitGutterAdd
hi link GitSignsChange  GitGutterChange
hi link GitSignsDelete  GitGutterDelete

" some primitive colors customized on top of xoria256
highlight Normal        ctermfg=255 guifg=#ffffff  ctermbg=NONE guibg=NONE
highlight EndOfBuffer   ctermfg=240 guifg=#585858  ctermbg=NONE guibg=NONE
highlight Comment       ctermfg=035 guifg=#38B04A
highlight SpecialComment ctermfg=250 guifg=#99a899  gui=italic   " docstring
highlight Constant      ctermfg=204 guifg=#ff5f87
highlight PreProc       ctermfg=219 guifg=#ffafff
highlight SpecialKey    ctermfg=242 guifg=#666666
highlight Folded        ctermbg=60  guibg=#404056

highlight FoldColumn    ctermfg=236 guifg=#495057

" Tabline
highlight TabLineSel    guibg=#37b24d guifg=white  gui=bold

" Diff
" DiffAdd - inserted lines (dark green)
highlight DiffAdd       guibg=#103a05 guifg=NONE
" DiffDelete - deleted/filler lines (gray 246)
highlight DiffDelete    guibg=#949494
" DiffChange - changed lines (dark red)
highlight DiffChange    guibg=#471515 guifg=NONE
" DiffChange - changed 'text'(brighter red)
highlight DiffText      guibg=#721b1b guifg=NONE

" See: diffAdded, diffRemoved, diffChange, diffText, diffIndexLine
hi! @text.diff.add      guifg=#40c057
hi! @text.diff.delete   guifg=#f03e3e
hi! @attribute.diff     guifg=#da77f2

highlight SpellBad guifg=NONE ctermfg=NONE

" no underline, current cursor line
highlight CursorLine    cterm=none

" better popup menu colors (instead of dark black)
highlight Pmenu             ctermfg=black guifg=black ctermbg=yellow guibg=#ffec99
highlight PmenuSel          ctermfg=red guifg=red ctermbg=white guibg=white gui=bold
highlight PmenuThumb        ctermfg=243 ctermbg=15 guifg=#767676 guibg=white

" neovim: Default background for floating windows (should be dark, not Pmenu)
if hlexists('NormalFloat')
  highlight NormalFloat     ctermbg=233 ctermbg=white guibg=#121212 guifg=white
endif

" LSP
highlight!  LspInlayHint    guifg=#9e9e9e guibg=#232323 gui=italic

" Minimal treesitter syntax support
" see https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md#highlights
" The highlight mapping is not exhaustive; to see the list, try:
" :filter /^@/ highlight   (or :Highlights @)

hi! @constant                guifg=#ffaf00 gui=bold
hi! @field                   guifg=NONE
hi! @function                guifg=#ffaf00
hi! @function.call           guifg=#d7ff5f
hi! @parameter               guifg=#5fafff
hi! @property                guifg=NONE
hi! @punctuation.bracket     guifg=#afd700
hi! @punctuation.delimiter   guifg=NONE
hi! @variable                guifg=NONE
hi! @variable.builtin        guifg=#d78787 ctermfg=174   " e.g. self, this

hi! @string.injection         guifg=#ffffff guibg=#1c1313
hi! link @none                Normal

hi link @string.documentation          SpecialComment
hi link @comment.documentation         SpecialComment
hi link @comment.special               SpecialComment

hi! @text.strong                       gui=bold
hi! @text.emphasis                     gui=italic
hi! @text.underline                    gui=underline
hi! @text.strike                       gui=strikethrough
hi! link @text.strike                  Title
hi! @text.literal                      gui=italic
hi! @text.uri                          gui=italic,underline
hi def link @text.math                 Special
hi def link @text.environment          PreProc
hi def link @text.environment.name     Function
hi def link @text.environment.name     Keyword
hi def link @text.warning              WarningMsg

" LSP Semantic token support {{{
" ------------------------------
" https://microsoft.github.io/language-server-protocol/specification/#semanticTokenTypes
hi link @lsp.type.type                  @type
hi link @lsp.type.class                 @type
hi link @lsp.type.struct                @type
hi link @lsp.type.enum                  @type
hi link @lsp.type.interface             @type
hi link @lsp.type.typeAlias             @type
hi link @lsp.type.macro                 @preproc
hi link @lsp.type.builtinConstant       @constant.builtin
hi link @lsp.type.enumMember            @constant
hi link @lsp.type.operator              @operator
hi link @lsp.type.string                @string
hi link @lsp.type.namespace             @namespace
hi link @lsp.type.parameter             @parameter
hi link @lsp.type.decorator             @function
hi link @lsp.type.comment               @comment
hi link @lsp.type.lifetime              @storageclass

hi!     @lsp.type.typeParameter         guifg=#fae000 gui=bold
hi!     @lsp.type.generic               guifg=#fae000
hi!     @lsp.type.property              guifg=#afffaf
hi!     @lsp.type.variable              guifg=NONE
hi!     @lsp.type.unresolvedReference   guifg=#ffff00 gui=underline

" Do not use semantic token highlight; instead basic tressitter highlights
" (e.g. we want to distinguish @function.call from @function)
hi!     @lsp.type.method                guifg=NONE
hi!     @lsp.type.function              guifg=NONE

" }}}


" Common for programming languages
hi!      @type.qualifier              guifg=#3bc9db           " const, etc.
hi!      @storageclass                guifg=#3bc9db           " static, extern, etc.

" Comments (common lang injection)
" e.g., TODO WIP NOTE XXX INFO DOCS PERF TEST HACK WARN WARNING FIX FIXME BUG ERROR
hi! link @text.todo                Todo
hi! @text.note.comment             guibg=#b2f2bb guifg=black
hi! @text.warning.comment          guibg=#ffa94d guifg=black
hi! @text.danger.comment           guibg=#e03131 guifg=white

" Bash
hi! link @preproc.bash             SpecialComment
hi!      @command.bash             guifg=white
hi! link @variable.bash            PreProc
hi!      @parameter.bash           guifg=NONE

" Markdown
hi!      @text.literal.block.markdown        guibg=#3a3a3a                  " ```codeblock``` (injection)
hi! link @text.literal.markdown_inline       Constant
hi!      @text.reference.markdown_inline     guifg=#228be6 gui=underline    " link

" Help
hi!      @text.reference.vimdoc      ctermfg=182 guifg=#228be6 gui=underline
hi! link @text.literal.vimdoc        Constant
hi!      @text.literal.block.vimdoc  guifg=white guibg=#252525 gui=italic

" luadoc (see $VIMPLUG/nvim-treesitter/queries/luadoc/highlights.scm)
hi! link @comment.luadoc            @comment.documentation
" - various annotations
hi!      @keyword.luadoc            guifg=#a488a6 gui=NONE
hi! link @keyword.return.luadoc     @keyword.luadoc    " @return
hi! link @keyword.coroutine.luadoc  @keyword.luadoc    " @async
hi! link @include.luadoc            @keyword.luadoc    " @module, @package
hi! link @type.qualifier.luadoc     @keyword.luadoc    " @public, @private, etc.
" - @field: see nvim-treesitter/nvim-treesitter#5762
hi!      @field.lua                 guifg=NONE
hi!      @field.luadoc              guifg=#a4ad2b


" C/C++
hi!      @exception.cpp                           guifg=#ff5d62           " try, catch, ...
hi!      @lsp.type.comment.cpp                    guifg=#778377
hi! link @lsp.type.comment.c                      @lsp.type.comment.cpp
hi!      @lsp.typemod.class.definition.cpp        guifg=#ffaf00 gui=bold
"hi!      @punctuation.bracket.cpp     guifg=NONE


" Python (semantic highlighting and more syntax groups) {{{
" ---------------------------------------------------------

hi! link @preproc.python             SpecialComment

" attribute (self.xxx)
hi! link semshiAttribute        @lsp.type.property.python

" self: more distinctive color
hi! link pythonSelf             @variable.builtin.python
hi! link semshiSelf             @variable.builtin.python

" functions, methods
hi! link pythonFunction         @function.python
hi! link pythonParam            @parameter.python
hi! @parameter.python           guifg=#dfaf5f
hi! @function.python            guifg=#d7ff5f
hi! @method.python              guifg=#d7ff5f

hi! @function.test.python       guifg=#ffff30 gui=bold
hi! @method.test.python         guifg=#ffff30 gui=bold

" }}}

" Gitcommit
hi link @text.title.gitcommit       PreProc
hi!     @text.uri.gitcommit         guifg=#df6383 gui=NONE
