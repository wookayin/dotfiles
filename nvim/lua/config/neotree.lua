local M = {}


function M.setup_neotree()
  -- https://github.com/nvim-neo-tree/neo-tree.nvim#quickstart
  -- ~/.vim/plugged/neo-tree.nvim/lua/neo-tree/defaults.lua
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
          -- neo-tree's search does not work well, so I don't use it
          ["/"] = "none",
        },
      },

      -- This is a useful feature to turn on,
      -- but should be disabled for a workaround until #111 is fixed
      follow_current_file = false,
      use_libuv_file_watcher = false,

      -- #320: Do not hide hidden files when the root folder is otherwise empty
      filtered_items = {
        force_visible_in_empty_folder = true,
      },

      -- Append trailing slashes on directories (#112)
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
        default = "",
      },
      git_status = {
        symbols = {
          untracked = "?",
          unstaged = "*",
          staged = "✚",
        }
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
end

return M
