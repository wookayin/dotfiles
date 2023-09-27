---------------
-- Telescope
---------------

local telescope = require("telescope")

if not pcall(require, 'telescope.actions.layout') then
  vim.api.nvim_echo({
      {"Warning: Telescope is outdated and disabled. Please update the plugin.", "WarningMsg"}
    }, true, {})
  vim.cmd [[ silent! delcommand! Telescope ]]
  return false
end

-- @see  :help telescope.setup
-- @see  https://github.com/nvim-telescope/telescope.nvim#telescope-setup-structure
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

-- Custom Telescope mappings and aliases
local function define_commands()
  local command = function(name, opts, command)
    vim.validate {
      opts = { opts, 'table' },
      command = { command, { 'function', 'string' } }
    }
    if opts.alias then
      vim.fn.CommandAlias(opts.alias, name)
      opts.alias = nil
    end
    return vim.api.nvim_create_user_command(name, command, opts)
  end
  local nmap = function(...) vim.keymap.set('n', ...) end

  -- :te and :Te are shortcuts to telescope
  vim.fn.CommandAlias("te", "Telescope")
  vim.fn.CommandAlias("Te", "Telescope")

  -- Searching commands w/ telescope (plus, accepts arguments)
  -- NOTE: see $DOTVIM/lua/config/fzf.lua -- we prefer fzf-lua to telescope for many of the finders
  command("Maps", { nargs='?', complete='mapping' }, function(e)
    require("telescope.builtin").keymaps({
      default_text = vim.trim(e.args),
    })
  end)
  command("Commands", { nargs='?', complete='command' }, function(e)
    require("telescope.builtin").commands({
      default_text = vim.trim(e.args),
    })
  end)

  command("Highlights", { nargs='?', complete='highlight' }, function(e)
    require("telescope.builtin").highlights({
      default_text = vim.trim(e.args),
      sorter = require("telescope.sorters").fuzzy_with_index_bias(),  -- better sorting
    })
  end)
  vim.fn.CommandAlias("Hi", "Highlights")

  command("LspSymbols", { nargs='?' }, function(e)
    require("telescope.builtin").lsp_dynamic_workspace_symbols({
      default_text = vim.trim(e.args),
    })
  end)

end
define_commands()

-- Telescope extensions
-- These should be executed *AFTER* other plugins are loaded
vim.defer_fn(function()
  if pcall(require, "notify") then  -- nvim-notify
    telescope.load_extension("notify")
    vim.cmd [[ command! -nargs=0 Notifications  :Telescope notify ]]
  end
end, 0)
