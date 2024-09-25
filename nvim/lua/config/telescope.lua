---------------
-- Telescope
---------------

local M = {}

function M.setup_telescope()
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
      scroll_strategy = 'limit',  -- do not cycle!
      mappings = {
        i = {
          ["<C-u>"] = false,   -- Do not map <C-u>; CTRL-U should be backward-kill-line.
          ["<C-d>"] = false,
          -- Ctrl-f,b: scroll the result window (picker) like PageDn/PageUp
          ["<C-f>"] = require("telescope.actions").results_scrolling_down,
          ["<C-b>"] = require("telescope.actions").results_scrolling_up,
          -- Ctrl-e,y: scroll the preview window
          ["<C-e>"] = require("telescope.actions").preview_scrolling_down,
          ["<C-y>"] = require("telescope.actions").preview_scrolling_up,
          -- Ctrl-/: toggle preview
          ["<C-_>"] = require("telescope.actions.layout").toggle_preview,
        }
      }
    }
  }
  -- Highlights
  vim.cmd [[
    hi TelescopePrompt guibg=#1a2a31
  ]]
end

-- Custom Telescope mappings and aliases
function M.define_commands()
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

  command("LspSymbols", { nargs='?' }, function(e)
    require("telescope.builtin").lsp_dynamic_workspace_symbols({
      default_text = vim.trim(e.args),
    })
  end)

end

-- Telescope extensions: use require('config.telescope').on_ready
local extensions = {}

-- Register callbacks to set up other telescope extensions when telescope is ready
-- (this is because other plugins might be loaded earlier than lazy-loaded telescope)
function M.on_ready(callback)
  extensions[#extensions+1] = callback
end

function M.setup()
  M.setup_telescope()
  M.define_commands()

  for i, extension_cb in ipairs(extensions) do
    xpcall(extension_cb, vim.api.nvim_err_writeln)
  end
  extensions = {}
  M.on_ready = function(callback)
    xpcall(callback, vim.api.nvim_err_writeln)
  end
end

return M
