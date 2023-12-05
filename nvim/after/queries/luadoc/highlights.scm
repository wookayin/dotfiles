;; extends
; see $VIMPLUG/nvim-treesitter/queries/luadoc/highlights.scm


; capture fields in member_type as @field.lua.luadoc, not @field.luadoc
; nvim-treesitter/nvim-treesitter#5762
(member_type ["#" "."] . (identifier) @field.lua)
