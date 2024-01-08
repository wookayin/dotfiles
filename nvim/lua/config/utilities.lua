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

function M.setup_colorizer()
  -- https://github.com/NvChad/nvim-colorizer.lua#customization
  require('colorizer').setup {
    user_default_options = {
      RGB = true,
      RRGGBB = true,
      RRGGBBAA = true,
      names = true,
    },
    filetypes = {
      '*';
      css = { css = true, tailwind = true };
      scss = { css = true, tailwind = true };
      sass = { css = true, sass = { enable = true, parsers = {"css"} } };
      less = { css = true, tailwind = true };
      html = { css = true, tailwind = true };
      javascript = { css = true, tailwind = true };
      -- Update color values even if buffer is not focused (for cmp menu, etc.)
      cmp_docs = { always_update = true };
      cmp_menu = { always_update = true };
    },
    buftypes = {
      '*',
      '!prompt';
    }
  }
end

return M
