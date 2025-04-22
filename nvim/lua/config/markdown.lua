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
      border = { true, true, true, false, false, false }, -- only h1, h2, and h3
      backgrounds = nil,  ---@see render.md.Colors, e.g. RenderMarkdownH1Bg; see below
      position = 'inline',
      icons = { '# ', '## ', '### ', '#### ', '##### ', '###### ' },
    },
    bullet = {
      icons = { '•', '◦', '‣', '-' },
    },
    checkbox = {
      checked = { icon = '• ✅', },  -- raw = '[x]'
      unchecked = { icon = '• ⬜️', }, -- raw = '[ ]'
      custom = {
        todo = { rendered = '• ⏳', raw = '[-]', },
      }
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
    ---@param rhs vim.api.keyset.highlight
    local hl = function(group, rhs) vim.api.nvim_set_hl(0, group, rhs) end
    local fg_heading = '#282c34'
    local bg_heading = { '#c678dd', '#61afef', '#98c379' }
    hl('RenderMarkdownH1Bg', { fg = fg_heading, bg = bg_heading[1] })
    hl('RenderMarkdownH2Bg', { fg = fg_heading, bg = bg_heading[2] })
    hl('RenderMarkdownH3Bg', { fg = fg_heading, bg = bg_heading[3] })

    hl('RenderMarkdownCodeBorder', { fg = 'yellow', bg = '#222222', italic = true })
  end)

  require('render-markdown').setup(opts)

  -- Markdown buffers already loaded before lazy-loading needs manual attaching
  local file_types = vim.F.npcall(function()
    -- Private API. The 'ft' field of the lazy plugin spec will be read.
    return require('render-markdown.state').file_types
  end) or { 'markdown' } ---@type string[]

  require('utils.rc_utils').bufdo(function(buf)
    -- Attach on existing buffers (including unlisted buffers, e.g. hover docs, codecompanion)
    -- see $VIMPLUG/render-markdown.nvim/lua/render-markdown/manager.lua
    if vim.tbl_contains(file_types, vim.bo[buf].filetype) then
      vim.api.nvim_exec_autocmds('FileType', { buffer = buf, group = 'RenderMarkdown' })
    end
  end, { include_unlisted = true })
end

-- Resourcing support
if ... == nil then
  M.setup_render()
end

return M
