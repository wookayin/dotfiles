-- config/markdown.lua

local M = {}

function M.setup_render()
  -- :help render-markdown-setup
  ---@type render.md.UserConfig
  local opts = {
    heading = {
      border = { true, true, false, false, false, false }, -- only h1 and h2
      backgrounds = nil,  ---@see render.md.Colors, e.g. RenderMarkdownH1Bg
      position = 'inline',
      icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' },
    },
    bullet = {
      icons = { '•', '◦', '‣', '-' },
    },
    checkbox = {
      checked = { icon = '✅', },
      unchecked = { icon = '⬜️', },
    },
    code = {
      highlight = '@markup.raw.block.markdown',
      highlight_language = '@label.markdown',
      highlight_inline = '@markup.raw.block.markdown',
    },
    on = {
      attach = function(_)
        -- <Ctrl-/> to toggle markdown rendering (local to buffer)
        vim.keymap.set('n', '<c-/>', '<c-_>', { buffer = true })
        vim.keymap.set('n', '<c-_>', '<Cmd>RenderMarkdown buf_toggle<CR>', { buffer = true })
      end
    }
  }

  require('utils.rc_utils').RegisterHighlights(function()
    -- TODO: improve background color, or define highlight color on its own
    vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { link = 'lualine_a_normal' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { link = 'lualine_a_command' })
    vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { link = 'StatusLine' })
  end)

  -- for now, we don't use lazy loading so that startup markdown buffers can also be attached
  require('render-markdown').setup(opts)
end

return M
