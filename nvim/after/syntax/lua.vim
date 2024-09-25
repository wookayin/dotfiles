" Additional Lua Syntax
" written by Jongwook Choi (@wookayin)

let s:vimpath = fnameescape(expand("$VIMRUNTIME")."/syntax/vim.vim")
if !filereadable(s:vimpath)
 for s:vimpath in split(globpath(&rtp, "syntax/vim.vim"),"\n")
  if filereadable(fnameescape(s:vimpath))
   let s:vimpath = fnameescape(s:vimpath)
   break
  endif
 endfor
endif

if !filereadable(s:vimpath)
  finish
end

unlet! b:current_syntax

" ============================================================================
" Highlight vim.cmd [[ ... ]] region with vim syntax.
syn cluster luaVimCmdBodyList	add=LuaVimRegion
exe "syn include @vimLuaScript ".s:vimpath
syn region LuaVimRegion matchgroup=luaVimCmdDelim
    \ start=+\s*vim.cmd\s*\[\[\s*$+ end=+^\s*\]\]$+
    \ containedin=luaFunc,luaThenEnd,luaLoopBlock contains=@vimLuaScript fold
syn cluster luaVimCmdBodyList	add=LuaVimRegion

unlet s:vimpath
let b:current_syntax = 'lua'

" Highlight group for the delimeters (`vim.cmd [[` and `]]`)
hi def link luaVimCmdDelim     luaStringSpecial
