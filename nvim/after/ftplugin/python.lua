-- python.lua: python ftplugin
-- (see also python.vim)

-- Use treesitter highlight for python
-- Note: nvim >= 0.9 recommended, injection doesn't work well in 0.8.x
require("config.treesitter").setup_highlight('python')

-- LSP: turn on auto formatting by default for a 'project'
-- condition: when one have .style.yapf file in a git repository.
-- Executed only once for the current vim session.

local function maybe_enable_autoformat(args)
  -- Only on null-ls has been attached
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if not client then
    return
  elseif client.name ~= 'null-ls' then
    return
  end

  if vim.g._python_autoformatting_detected then
    return
  end

  vim.g._python_autoformatting_detected = 1  -- do not auto-turn on any more
  vim.schedule(function()
    local project_root = vim.fn.DetermineProjectRoot()
    if project_root and project_root ~= "" then
      local style_yapf = project_root .. '/.style.yapf'
      if vim.fn.filereadable(style_yapf) > 0 then
        vim.cmd['LspAutoFormattingOn'](style_yapf)
      end
    end
  end)
end

vim.api.nvim_create_autocmd('LspAttach', {
  once = true,
  buffer = vim.fn.bufnr(),
  callback = maybe_enable_autoformat,
})

------------------------------------------------------------------------------
-- Keymaps (see $DOTVIM/lua/lib/python.lua)
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
local function make_repeatable_toggle_keymap(comment)
  local auto_lhs = ("<Plug>(ToggleLineComment-%s)"):format(comment:gsub('%W', ''))
  return make_repeatable_keymap('n', auto_lhs, function()
    require("lib.python").toggle_line_comment(comment)
  end)
end
bufmap('n', '<leader>ti', make_repeatable_toggle_keymap("type: ignore"), { remap = true })
bufmap('n', '<leader>ty', make_repeatable_toggle_keymap("yapf: ignore"), { remap = true })
