-- python.lua: python ftplugin
-- (see also python.vim)

-- Basic buffer options (indent size, etc.)
-- Note: FileType triggered again after editorconfig might override options, so set it again
local indent_size = tonumber((vim.b.editorconfig or {}).indent_size) or 4
vim.opt_local.expandtab = true
vim.opt_local.ts = indent_size
vim.opt_local.sw = indent_size
vim.opt_local.sts = indent_size

vim.g.python_recommended_style = 0  -- Prevent $VIMRUNTIME/ftplugin/python.vim from overridding tabsize

-- line-length: 79 by default, TODO read from pyproject.toml
vim.opt_local.textwidth = 79
vim.opt_local.colorcolumn = '+1'

-- Use treesitter highlight for python
-- Note: nvim >= 0.9 recommended, injection doesn't work well in 0.8.x
require("config.treesitter").setup_highlight('python')

-- Formatting
require("config.formatting").create_buf_command("Isort", "isort")
require("config.formatting").create_buf_command("Yapf", "yapf")
require("config.formatting").create_buf_command("Black", "black")

local bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_create_autocmd('LspAttach', {
  once = true,
  buffer = bufnr,
  callback = function()
    require("config.formatting").maybe_autostart_autoformatting(bufnr, function(project_root)
      -- Autoformatting: detect yapf, isort independently.
      local formatters = {} ---@type table<"yapf"|"isort",string> formatter -> reason

      local style_yapf = assert(project_root) .. '/.style.yapf'
      if vim.fn.filereadable(style_yapf) > 0 then
        formatters["yapf"] = ("Detected `%s`"):format(style_yapf)
      end
      local pyproject_toml = assert(project_root) .. '/pyproject.toml'
      if vim.fn.filereadable(pyproject_toml) > 0 then
        -- TODO: avoid scanning the file twice.
        local file_contains_pattern = require("utils.path_utils").file_contains_pattern
        for formatter, pattern in pairs {
          yapf = "^%[tool%.yapf%]",
          isort = "^%[tool%.isort%]",
        } do
          _, match = file_contains_pattern(pyproject_toml, { pattern })
          if match then
            formatters[formatter] = ("`pyproject.toml:%s: %s`"):format(match.line, match.match)
          end
        end
      end

      if vim.tbl_isempty(formatters) then
        return false, nil
      else
        local reason = table.concat(vim.tbl_values(formatters), '\n')
        return vim.tbl_keys(formatters), reason
      end
    end)
  end,
})

local bufcmd = function(...) return vim.api.nvim_buf_create_user_command(0, ...) end
bufcmd('RuffFixAll', function(_)
  vim.lsp.buf.code_action {
    apply = true,
    filter = function(action)
      return action.title == "Ruff: Fix All"
    end,
  }
end, { })

------------------------------------------------------------------------------
-- More Keymaps (see $DOTVIM/lua/lib/python.lua)
------------------------------------------------------------------------------
local vim_cmd = function(x) return '<Cmd>' .. vim.trim(x) .. '<CR>' end
local bufmap = function(mode, lhs, rhs, opts)
  return vim.keymap.set(mode, lhs, rhs, vim.tbl_deep_extend("error", { buffer = true }, opts or {}))
end
local make_repeatable_keymap = require("utils.rc_utils").make_repeatable_keymap

-- Toggle breakpoint (a non-DAP way)
bufmap('n', '<leader>b', '<Plug>(python-toggle-breakpoint)', { remap = true })
vim.keymap.set('n', '<Plug>(python-toggle-breakpoint)', function()
  require("lib.python").toggle_breakpoint()
end, { buffer = false })

-- Toggle f-string
local toggle_fstring = vim_cmd [[ lua require("lib.python").toggle_fstring() ]]
bufmap('n', '<leader>tf', make_repeatable_keymap('n', '<Plug>(toggle-fstring-n)', toggle_fstring), { remap = true })
bufmap('i', '<C-f>', toggle_fstring)

-- Toggle line comments (e.g., `type: ignore`, `yapf: ignore`)
local function make_repeatable_toggle_comment_keymap(comment)
  local auto_lhs = ("<Plug>(ToggleLineComment-%s)"):format(comment:gsub('%W', ''))
  return make_repeatable_keymap('n', auto_lhs, function()
    require("lib.python").toggle_line_comment(comment)
  end)
end
bufmap('n', '<leader>ti', make_repeatable_toggle_comment_keymap("type: ignore"), { remap = true })
bufmap('n', '<leader>ty', make_repeatable_toggle_comment_keymap("yapf: ignore"), { remap = true })

-- Insert pylint directives (via ultisnips)
local ultisnips_expand = '<C-R>=UltiSnips#ExpandSnippet()<CR>'
bufmap('n', '<leader>tl', 'A  pylint' .. ultisnips_expand)
bufmap('n', '<leader>tL', 'Opylint' .. ultisnips_expand)

-- Toggle Optional[...], Annotated[...] for typing
bufmap('n', '<leader>O', '<leader>tO', { remap = true })
bufmap('n', '<leader>tO', make_repeatable_keymap('n', '<Plug>(toggle-Optional)', function()
  require("lib.python").toggle_typing("Optional")
end), { remap = true })
bufmap('n', '<leader>tA', make_repeatable_keymap('n', '<Plug>(toggle-Annotated)', function()
  require("lib.python").toggle_typing("Annotated")
end), { remap = true })
