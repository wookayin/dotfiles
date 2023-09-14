------------
-- fzf + lua
------------

-- https://github.com/ibhagwan/fzf-lua, replaces fzf.vim

local M = {}

local function extend(lhs)
  return function(rhs) return vim.tbl_deep_extend("force", lhs, rhs) end
end

function M.setup()
  local defaults = require('fzf-lua.defaults').defaults

  require('fzf-lua').setup {
    keymap = {
      -- 'builtin' means keymap for the neovim's terminal buffer (tmap <buffer>)
      builtin = extend(defaults.keymap.builtin) {
        ["<Esc>"] = "abort",
        ["<C-/>"] = "toggle-preview",
        ["<C-_>"] = "toggle-preview",
      },
      -- 'fzf' means keymap that is directly fed to the fzf process (fzf --bind)
      fzf = extend(defaults.keymap.fzf) {
        ["ctrl-/"] = "toggle-preview",
      },
    },
    winopts = {
      width = 0.90,
      height = 0.80,
      preview = {
        vertical = "down:45%",
        horizontal = "right:50%",
        layout = "flex",
      },
      on_create = function()
        -- Some (global) terminal keymaps should be disabled for fzf-lua, see GH-871
        local keys_passthrough = { '<C-e>', '<C-y>' }
        local bufnr = vim.api.nvim_get_current_buf()
        for _, key in ipairs(keys_passthrough) do
          vim.keymap.set('t', key, key, { buffer = bufnr, remap = false, silent = true, nowait = true })
        end
      end,
    },

    -- Customize builtin finders
    autocmds = {
      winopts = { preview = { layout = "vertical", vertical = "down:33%" } },
    },
  }

  ---[[ Highlights ]]
  ---https://github.com/ibhagwan/fzf-lua#highlights
  require("utils.rc_utils").RegisterHighlights(function()
    vim.cmd [[
      hi!      FzfLuaNormal guibg=#151b21
      hi! link FzfLuaBorder FzfLuaNormal
    ]]
  end)

  ---[[ Commands ]]
  local command_alias = vim.fn.CommandAlias
  command_alias("FL", "FzfLua")

  -- TODO: Migrate commands provided by $VIMPLUG/fzf.vim/plugin/fzf.vim:53
  -- Files, GitFiles, GFiles, Buffers, Lines, BLines, Colors, Locate,
  -- Ag, Rg, RG, Tags, BTags, Snippets, Commands, Jumps, Marks, Helptags,
  -- Windows, Commits, BCommits, Maps, Filetypes, History

  ---[[ Keymaps ]]
  -- TODO: Add insert mode keymaps <plug>(fzf-complete-*)

  ---[[ Misc. ]]
  _G.fzf = require('fzf-lua')
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end

(RC or {}).fzf = M
return M
