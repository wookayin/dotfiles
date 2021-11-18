---------------
-- Telescope
---------------
-- @see  :help telescope.setup
-- @see  https://github.com/nvim-telescope/telescope.nvim#telescope-setup-structure
local telescope = require("telescope")

if not pcall(require, 'telescope.actions.layout') then
  vim.api.nvim_echo({
      {"Warning: Telescope is outdated and disabled. Please update the plugin.", "WarningMsg"}
    }, true, {})
  vim.cmd [[ silent! delcommand! Telescope ]]
  do return end
end

telescope.setup {
  defaults = {
    winblend = 10,
    layout_strategy = 'horizontal',
    layout_config = {  -- :help telescope.layout
      horizontal = { width = 0.9 },
      mirror = false,
      prompt_position = 'top',
    },
    sorting_strategy = 'ascending',  -- with prompt_position='top'
    mappings = {
      i = {
        ["<C-u>"] = false,   -- Do not map <C-u>; CTRL-U should be backward-kill-line.
        ["<C-d>"] = false,
        ["<C-b>"] = require("telescope.actions").preview_scrolling_up,
        ["<C-f>"] = require("telescope.actions").preview_scrolling_down,
        ["<C-_>"] = require("telescope.actions.layout").toggle_preview,
      }
    }
  }
}
-- Highlights
vim.cmd [[
  hi TelescopePrompt guibg=#1a2a31
]]

-- Custom Telescope mappings
vim.cmd [[
command! -nargs=0 Highlights    :Telescope highlights
command! -nargs=0 CodeActions   :Telescope lsp_code_actions
call CommandAlias("CA", "CodeActions")
call CommandAlias("Te", "Telescope")
]]

-- Telescope extensions
-- These should be executed *AFTER* other plugins are loaded
vim.defer_fn(function()
  if vim.fn['HasPlug']('nvim-notify') == 1 then
    telescope.load_extension("notify")
    vim.cmd [[ command! -nargs=0 Notifications  :Telescope notify ]]
  end
end, 0)
