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

function M.setup_osc52()
  local _called_setup = false  -- for lazy-loading

  -- Text yanked to the "+" register will be copied to the system clipboard
  -- over the SSH session using the OSC52 sequence.
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup('osc52', { clear = true }),
    callback = function()
      if not _called_setup then
        _called_setup = true
        require("osc52").setup {
          tmux_passthrough = true,
        }
      end

      if vim.v.event.regname == "+" and vim.v.event.operator == "y" then
        require("osc52").copy_register("+")
      end
    end
  })
end

return M
