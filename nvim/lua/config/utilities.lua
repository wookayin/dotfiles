------------
-- Utilities
------------

local M = {}

function M.setup_hover()
  require("hover").setup {
    init = function()
      require("hover.providers.lsp")
      require('hover.providers.gh')
      require('hover.providers.gh_user')
      require('hover.providers.man')
    end,
    preview_opts = {
      border = nil
    },
    -- Whether the contents of a currently open hover window should be moved
    -- to a :h preview-window when pressing the hover keymap.
    preview_window = false,
    title = true,
  }

end


return M
