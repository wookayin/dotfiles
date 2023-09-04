local M = {}

function M.setup_neotree()
  -- https://github.com/nvim-neo-tree/neo-tree.nvim#quickstart
  -- $VIMPLUG/neo-tree.nvim/lua/neo-tree/defaults.lua
  require('neo-tree').setup {
    filesystem = {
      hijack_netrw_behavior = "open_current",
      window = {
        width = 30,

        mappings = {
          ["r"] = "refresh",
          ["R"] = "rename",
          ["I"] = "toggle_hidden",
          -- Do not reserve default vim keybindings (I want zt, zz, etc.)
          ["z"] = "none",
          ["H"] = "none",
          ["l"] = "none",  -- make h,l navigation work
          -- neo-tree's search does not work well, so I don't use it
          ["/"] = "none",
        },
      },

      follow_current_file = {
        enabled = true,
      },
      use_libuv_file_watcher = false,

      -- #320: Do not hide hidden files when the root folder is otherwise empty
      filtered_items = {
        force_visible_in_empty_folder = true,
      },

      -- Append trailing slashes on directories (#112, $483)
      components = {
        trailing_slash = function ()
          return {
            text = "/",
            highlight = "NeoTreeDirectoryIcon",
          }
        end,
      },
      renderers = {
        directory = {
          {"icon"},
          {"name", use_git_status_colors = false, right_padding = 0},
          {"trailing_slash"},
          {"diagnostics"},
          {"git_status"},
        }
      },
    },

    -- Layout (see #130)
    default_component_configs = {
      indent = {
        with_markers = true,
        indent_marker = "│",
        last_indent_marker = "└",
        indent_size = 2,
        padding = 0, -- extra padding on the left hand side
      },
      icon = {
        default = "󰈙",  -- nf-md-file_document
        folder_closed = "󰉋", -- nf-md-folder
        folder_open = "󰝰",  -- nf-md-folder-open
        folder_empty = "󰉖",  -- nf-md-folder_outline
        folder_empty_open = "󰉖", -- nf-md-folder_outline
      },
      git_status = {
        symbols = {
          untracked = "?",
          unstaged = "*",
          renamed = "󰁕",
          staged = "✚",
        }
      },
    },
    -- just default settings, but use nerd-font v3 unicodes (#909, #921)
    document_symbols = {
      kinds = {
        File = { icon = "󰈙", hl = "Tag" },
        Namespace = { icon = "󰌗", hl = "Include" },
        Package = { icon = "󰏖", hl = "Label" },
        Class = { icon = "󰌗", hl = "Include" },
        Property = { icon = "󰆧", hl = "@property" },
        Enum = { icon = "󰒻", hl = "@number" },
        Function = { icon = "󰊕", hl = "Function" },
        String = { icon = "󰀬", hl = "String" },
        Number = { icon = "󰎠", hl = "Number" },
        Array = { icon = "󰅪", hl = "Type" },
        Object = { icon = "󰅩", hl = "Type" },
        Key = { icon = "󰌋", hl = "" },
        Struct = { icon = "󰌗", hl = "Type" },
        Operator = { icon = "󰆕", hl = "Operator" },
        TypeParameter = { icon = "󰊄", hl = "Type" },
        StaticMethod = { icon = "󰠄", hl = 'Function' },
      },
    },
  }

  -- Highlights for neotree
  require "utils.rc_utils".RegisterHighlights(function()
    vim.cmd [[
      hi link NeoTreeDirectoryName Directory
      hi NeoTreeGitUntracked guifg=#E3DB88
      hi NeoTreeGitIgnored guifg=#acacac
    ]]
  end)

  -- Keymaps
  vim.cmd [[
    nmap <leader>E  :Neotree toggle<CR>
  ]]

  _G.neotree = require('neo-tree')
end


--[[ Utilities ]]

--- Get the current path of a specific neotree window or the current neotree window.
--- https://github.com/nvim-neo-tree/neo-tree.nvim/discussions/319
function M.get_path(winid)
  -- On a 'netrw-style' neotree window. If it's not a neotree buffer, returns nil.
  winid = winid or vim.api.nvim_get_current_win()
  local state = require("neo-tree.sources.manager").get_state("filesystem", nil, winid)
  if state.path then
    return state.path
  end

  -- Possibly it's a sidebar style neotree.
  local bufnr = vim.api.nvim_win_get_buf(winid)
  if vim.bo[bufnr].filetype == 'neo-tree' then
    state = require("neo-tree.sources.manager").get_state("filesystem")
    if state.path then
      return state.path
    end
  end

  -- Not found, probably the window is not having a neotree.
  return nil
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup_neotree()
end

(RC or {}).neotree = M
return M
