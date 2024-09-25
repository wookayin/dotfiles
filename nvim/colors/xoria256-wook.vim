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

" for showing tabs, etc. (set 'list') -- don't stand out
highlight Whitespace    guifg=#333333 guibg=#121212

" gitsigns sign column
"  guibg=<X> and ctermbg=<Y> should match that of SignColumn
highlight GitSignsAdd             guifg=#009900 guibg=#121212 ctermfg=2 ctermbg=233
highlight GitSignsChange          guifg=#bbbb00 guibg=#121212 ctermfg=3 ctermbg=233
highlight GitSignsDelete          guifg=#ff2222 guibg=#121212 ctermfg=1 ctermbg=233
hi! link  GitSignsUntracked       GitSignsAdd
highlight GitSignsStagedAdd       guifg=#336600 guibg=#121212 ctermfg=2 ctermbg=233 gui=bold
highlight GitSignsStagedChange    guifg=#aa9900 guibg=#121212 ctermfg=3 ctermbg=233 gui=bold
highlight GitSignsStagedDelete    guifg=#bb2222 guibg=#121212 ctermfg=1 ctermbg=233 gui=bold

" some primitive colors customized on top of xoria256
highlight Normal        ctermfg=255 guifg=#ffffff  ctermbg=NONE guibg=NONE
highlight EndOfBuffer   ctermfg=240 guifg=#585858  ctermbg=NONE guibg=NONE
highlight Visual        ctermfg=NONE guifg=NONE   ctermbg=96  guibg=#875f87
highlight Comment       ctermfg=035 guifg=#38B04A
highlight SpecialComment ctermfg=250 guifg=#99a899  gui=italic   " docstring
highlight Constant      ctermfg=204 guifg=#ff5f87
highlight PreProc       ctermfg=219 guifg=#ffafff
highlight SpecialKey    ctermfg=242 guifg=#666666
highlight Folded        ctermbg=60  guibg=#292933

" Fallback: neovim/neovim#26540
hi def link Delimiter   Special
hi def link Operator    Statement

highlight FoldColumn    ctermfg=236 guifg=#495057

" tabline, winbar
highlight TabLineSel    guibg=#37b24d guifg=white  gui=bold
highlight WinBar        guibg=#000000
highlight WinBarNC      guibg=#000000

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
hi! @diff.plus          guifg=#40c057
hi! @diff.minus         guifg=#f03e3e
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

" Treesitter syntax support
" see https://github.com/nvim-treesitter/nvim-treesitter/blob/master/CONTRIBUTING.md#highlights
" :help treesitter-highlight-groups
" The highlight mapping is not exhaustive; to see the list, try:
" :filter /^@/ highlight   (or :Highlights @)

hi! @constant                guifg=#ffaf00
hi! @function                guifg=#ffaf00
hi! @function.call           guifg=#d7ff5f
hi! @property                guifg=NONE
hi! @punctuation.bracket     guifg=#afd700
hi! @punctuation.delimiter   guifg=NONE
hi! @variable                guifg=NONE
hi! @variable.member         guifg=NONE
hi! @variable.parameter      guifg=#5fafff
hi! @variable.builtin        guifg=#d78787 ctermfg=174   " e.g. self, this

hi! @string.injection         guifg=#ffffff guibg=#1c1313
hi! link @none                Normal

hi link @string.documentation          SpecialComment
hi link @comment.documentation         SpecialComment
hi link @comment.special               SpecialComment

hi link @string.special.url            Underlined

hi! @markup.strong                     gui=bold
hi! @markup.italic                     gui=italic
hi! @markup.underline                  gui=underline
hi! @markup.strikethrough              gui=strikethrough
hi! @markup.raw                        gui=italic
hi! @markup.link.url                   gui=italic,underline
hi def link @markup.math               Special
hi def link @markup.environment        PreProc
hi def link @markup.environment.name   Function
hi def link @markup.environment.name   Keyword

" Diagnostics
hi!     DiagnosticUnnecessary           gui=underline guifg=#87d7ff
hi!     DiagnosticUnderlineError        gui=undercurl guisp=#e03131
hi!     DiagnosticUnderlineWarn         gui=undercurl guisp=#fce094
hi!     DiagnosticUnderlineInfo         gui=underline guisp=#777777

if index(["wezterm", "alacritty", "xterm-kitty"], $TERM) < 0
  " if TERM does not support colored underline (e.g. xterm-256color),
  " undercurl falling back to white color can look quite annoying.
  hi!     DiagnosticUnderlineInfo       gui=NONE
end

" LSP Semantic token support {{{
" ------------------------------
" https://microsoft.github.io/language-server-protocol/specification/#semanticTokenTypes
" :help lsp-semantic-highlight
hi link @lsp.type.type                  @type
hi link @lsp.type.class                 @type
hi link @lsp.type.struct                @type
hi link @lsp.type.enum                  @type
hi link @lsp.type.interface             @type
hi link @lsp.type.typeAlias             @type
hi link @lsp.type.macro                 @keyword.directive
hi link @lsp.type.builtinConstant       @constant.builtin
hi link @lsp.type.enumMember            @constant
hi link @lsp.type.operator              @operator
hi link @lsp.type.string                @string
hi link @lsp.type.namespace             @module
hi link @lsp.type.parameter             @variable.parameter
hi link @lsp.type.decorator             @type.qualifier
hi link @lsp.type.comment               @comment
hi link @lsp.type.lifetime              @keyword.storageclass

hi! link @lsp.mod.documentation         @comment.documentation

hi!     @lsp.type.typeParameter         guifg=#fae000 gui=bold
hi!     @lsp.type.generic               guifg=#fae000
hi!     @lsp.type.property              guifg=#afffaf
hi!     @lsp.type.variable              guifg=NONE
hi!     @lsp.type.unresolvedReference   guifg=#ffff00 gui=underline

" hi!     @lsp.mod.declaration            gui=bold

" Do not use semantic token highlight; instead basic tressitter highlights
" (e.g. we want to distinguish @function.call from @function)
hi!     @lsp.type.method                guifg=NONE
hi!     @lsp.type.function              guifg=NONE

" }}}


" Common for programming languages
hi!      @type.qualifier                guifg=#3bc9db           " const, etc.
hi!      @keyword.storageclass          guifg=#3bc9db           " static, extern, etc.

" Comments (common lang injection)
" e.g., TODO WIP NOTE XXX INFO DOCS PERF TEST HACK WARN WARNING FIX FIXME BUG ERROR
hi! link @comment.todo               Todo
hi! @comment.note                    guibg=#b2f2bb guifg=black
hi! @comment.warning                 guibg=#ffa94d guifg=black
hi! @comment.error                   guibg=#e03131 guifg=white

" Bash
hi! link @keyword.directive.bash             SpecialComment
hi!      @command.bash             guifg=white
hi! link @variable.bash            PreProc
hi!      @variable.parameter.bash  guifg=NONE

" Markdown
hi!      @markup.raw.block.markdown          guibg=#3a3a3a                  " ```codeblock``` (injection)
hi!      @markup.link.markdown_inline        guifg=#228be6 gui=underline    " link
hi!      @markup.quote.markdown              guifg=#77ef4f

hi def link   @markup.raw.markdown_inline       Constant
hi def link   @markup.heading                   Title

" Help (vimdoc)
hi!      @markup.link.vimdoc         ctermfg=182 guifg=#228be6 gui=underline
hi! link @markup.raw.vimdoc          Constant
hi!      @markup.raw.block.vimdoc    guifg=white guibg=#252525 gui=italic

" Regex injections
hi!      @punctuation.bracket.regex     guifg=#99c9a9

" Lua
hi!      @lsp.mod.defaultLibrary.lua    guifg=#ffbf80
hi!      @lsp.type.property.lua         guifg=NONE
hi!      @lsp.type.comment.lua          guifg=NONE       " don't override luadoc
hi!      @lsp.type.keyword.lua          guifg=NONE       " don't override luadoc
hi!      @lsp.type.macro.lua            guifg=NONE       " don't override luadoc
hi!      @lsp.mod.documentation.lua     guifg=NONE       " don't override luaodc

hi!      @lsp.mod.global.lua                        gui=bold guifg=#ffaf00
hi!      @lsp.mod.declaration.lua                   gui=bold

hi!      @lsp.typemod.class.declaration.lua         gui=bold guifg=#ffaf00
hi!      @lsp.typemod.variable.declaration.lua      gui=bold guifg=#aeeeda
hi!      @lsp.typemod.property.declaration.lua      gui=bold
hi! link @lsp.typemod.function.declaration.lua      @function.lua
hi!      @lsp.typemod.parameter.declaration.lua     gui=bold

" luadoc (see $VIMPLUG/nvim-treesitter/queries/luadoc/highlights.scm)
hi! link @comment.luadoc            @comment.documentation
" - various annotations
hi!      @keyword.luadoc            guifg=#a488a6 gui=NONE
hi! link @keyword.return.luadoc     @keyword.luadoc    " @return
hi! link @keyword.coroutine.luadoc  @keyword.luadoc    " @async
hi! link @keyword.import.luadoc     @keyword.luadoc    " @module, @package
hi! link @type.qualifier.luadoc     @keyword.luadoc    " @public, @private, etc.
" - field: see nvim-treesitter/nvim-treesitter#5762 and 5895
hi!      @variable.member.lua                 guifg=NONE
hi! link @variable.member.lua.luadoc          @type.lua
hi!      @variable.member.luadoc              guifg=#a4ad2b

hi! link @punctuation.delimiter.luadoc     @punctuation.bracket         " comma e.g. table<string, integer>
hi! link @punctuation.special.luadoc       @string.special              " optional e.g. integer?

" operator inside type, e.g. foo|bar: no italic, see SpecialComment
hi!      @operator.luadoc                  guifg=#99a899 gui=NONE,nocombine


" C/C++
hi!      @keyword.exception.cpp                   guifg=#ff5d62           " try, catch, ...
hi!      @lsp.type.comment.cpp                    guifg=#778377
hi! link @lsp.type.comment.c                      @lsp.type.comment.cpp
hi!      @lsp.typemod.class.definition.cpp        guifg=#ffaf00 gui=bold
"hi!      @punctuation.bracket.cpp     guifg=NONE


" Python (semantic highlighting and more syntax groups) {{{
" ---------------------------------------------------------

hi! link @keyword.directive.python             SpecialComment

" attribute (self.xxx)
hi! link semshiAttribute        @lsp.type.property.python

" self: more distinctive color
hi! link pythonSelf             @variable.builtin.python
hi! link semshiSelf             @variable.builtin.python

" functions, methods
hi! link pythonFunction         @function.python
hi! link pythonParam            @variable.parameter.python
hi! @variable.parameter.python  guifg=#dfaf5f
hi! @function.python            guifg=#d7ff5f
hi! @function.method.python     guifg=#d7ff5f

hi! @function.test.python           guifg=#ffff30 gui=bold
hi! @function.method.test.python    guifg=#ffff30 gui=bold

" Override semantic token highlights (basedpyright):
" No highlights for import module/package
hi! @lsp.type.namespace.python  guifg=NONE

" }}}

" Gitcommit
hi!      @string.special.url.gitcommit    guifg=#df6383 gui=NONE
hi! link @markup.heading.gitcommit        PreProc
hi!      @comment.warning.gitcommit       guibg=NONE gui=undercurl guisp=#ffa94d
