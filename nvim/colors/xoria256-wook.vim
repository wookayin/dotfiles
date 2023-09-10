" Vim color file
"
" Name:            xoria256-wook.vim
" Original Author: Dmitriy Y. Zotikov <xio@unground.org>
"
" This is a colorscheme based on xoria256 but with more customization added.

runtime colors/xoria256.vim

let g:colors_name = "xoria256-wook"



" override more customized colors
highlight StatusLine    ctermfg=LightGreen
highlight ColorColumn   ctermbg=52 guibg=#5f0000

highlight LineNr        ctermfg=248 ctermbg=233   guifg=#a8a8a8 guibg=#121212
highlight CursorLineNr  cterm=none gui=bold
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
hi SpecialComment       ctermfg=250 guifg=#99a899  gui=italic   " docstring
highlight Constant      ctermfg=204 guifg=#ff5f87
highlight PreProc       ctermfg=219 guifg=#ffafff
highlight SpecialKey    ctermfg=242 guifg=#666666
highlight Folded        ctermbg=60  guibg=#404056

highlight FoldColumn    ctermfg=236 guifg=#495057

" colors for gui/24bit mode {{
" DiffAdd - inserted lines (dark green)
highlight DiffAdd       guibg=#103a05 guifg=NONE
" DiffDelete - deleted/filler lines (gray 246)
highlight DiffDelete    guibg=#949494
" DiffChange - changed lines (dark red)
highlight DiffChange    guibg=#471515 guifg=NONE
" DiffChange - changed 'text'(brighter red)
highlight DiffText      guibg=#721b1b guifg=NONE
" }}

highlight SpellBad guifg=NONE ctermfg=NONE

" no underline, current cursor line
highlight CursorLine    cterm=none

" better popup menu colors (instead of dark black)
highlight Pmenu             ctermfg=black guifg=black ctermbg=yellow guibg=#ffec99
highlight PmenuSel          ctermfg=red guifg=red ctermbg=white guibg=white gui=bold

" neovim: Default background for floating windows (should be dark, not Pmenu)
if hlexists('NormalFloat')
  highlight NormalFloat     ctermbg=233 guibg=#121212
endif

" Minimal treesitter syntax support
" The highlight mapping is not exhaustive; to see the list, try:
" :filter /^@/ highlight   (or :Highlights)

hi! @constant                guifg=#ffaf00 gui=bold
hi! @field                   guifg=NONE
hi! @function                guifg=#ffaf00
hi! @function.call           guifg=#d7ff5f
hi! @parameter               guifg=#5fafff
hi! @property                guifg=NONE
hi! @punctuation.bracket     guifg=#afd700
hi! @punctuation.delimiter   guifg=NONE
hi! @variable                guifg=NONE
hi def link @none            Normal

hi link @string.documentation          SpecialComment

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

" Bash
hi! link @preproc.bash             SpecialComment
hi!      @parameter.bash           guifg=NONE

" Markdown
hi! @text.literal.block.markdown   guibg=#3a3a3a

" Python (semantic highlighting and more syntax groups)
" -----------------------------------------------------

hi! link @preproc.python             SpecialComment

" attribute (self.xxx)
hi! semshiAttribute      ctermfg=157     guifg=#afffaf

" self: more distinctive color
hi! pythonSelf           ctermfg=174     guifg=#d78787
hi! semshiSelf           ctermfg=174     guifg=#d78787

" functions, methods
hi! link pythonFunction         @function.python
hi! link pythonParam            @parameter.python
hi! @parameter.python           guifg=#dfaf5f
hi! @function.python            guifg=#d7ff5f
hi! @method.python              guifg=#d7ff5f

hi! @function.test.python       guifg=#ffff30 gui=bold
hi! @method.test.python         guifg=#ffff30 gui=bold
