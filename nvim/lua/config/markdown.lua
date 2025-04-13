-- config/markdown.lua

local M = {}

function M.setup_render()
  -- :help render-markdown-setup
  ---@type render.md.UserConfig
  local opts = {
    -- Include the insert mode as well (to avoid flickering during mode change),
    -- but exclude the visual modes because we would want letter-precise visual blocks
    render_modes = { 'n', 'c', 't', 'i' },

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
      highlight_inline = '@markup.raw.markdown_inline',

      -- Nvim 0.11 can completely conceal vertical lines, hiding the lines (```) around codeblocks.
      -- This can be inconvenient while scrolling, so we don't want to hide the entire line.
      border = 'thin',
    },
    on = {
      attach = function(_)
        -- <Ctrl-/> to toggle markdown rendering (local to buffer)
        vim.keymap.set('n', '<c-/>', '<c-_>', { buffer = true, remap = true })
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

  require('render-markdown').setup(opts)

  -- Markdown buffers already loaded before lazy-loading needs manual attaching
  require('utils.rc_utils').bufdo(function(buf)
    if vim.bo[buf].filetype == 'markdown' then
      vim.api.nvim_exec_autocmds('FileType', { buffer = buf, group = 'RenderMarkdown' })
    end
  end)
end

-- Resourcing support
if ... == nil then
  M.setup()
end

return M
