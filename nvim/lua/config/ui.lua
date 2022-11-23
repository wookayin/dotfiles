-- config/ui.lua
-- Settings for UI-related components.

if pcall(require, 'dressing') then
  -- Prettier vim.ui.select() and vim.ui.input()

  -- https://github.com/stevearc/dressing.nvim#configuration
  require 'dressing'.setup {

    input = {
      -- the greater of 140 columns or 90% of the width
      prefer_width = 80,
      max_width = { 140, 0.9 },
    },

    select = {
    },

  }

end
