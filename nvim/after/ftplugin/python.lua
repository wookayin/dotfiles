-- python.lua: python ftplugin
-- (see also python.vim)

-- LSP: turn on auto formatting by default for a 'project'
-- condition: when one have .style.yapf file in a git repository.
-- Executed only once for the current vim session.

local function maybe_enable_autoformat(args)
  -- Only on null-ls has been attached
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if client.name ~= 'null-ls' then
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

if vim.fn.exists('##LspAttach') > 0 then
  vim.api.nvim_create_autocmd('LspAttach', {
    once = true,
    buffer = vim.fn.bufnr(),
    callback = maybe_enable_autoformat,
  })
end

-- Use treesitter highlight for python
-- Note: nvim >= 0.9 recommended, injection doesn't work well in 0.8.x
require("config.treesitter").setup_highlight('python')

------------------------------------------------------------------------------
-- Keymaps
------------------------------------------------------------------------------

-- Breakpoint toggle
vim.keymap.set('n', '<leader>b', '<Plug>(python-toggle-breakpoint)', { buffer = true, remap = true })
vim.keymap.set('n', '<Plug>(python-toggle-breakpoint)', function()
  local pattern = "breakpoint()"  -- Use python >= 3.7.
  local line = vim.fn.getline(".") --[[@as string]]
  line = vim.trim(line)
  local lnum = vim.fn.line(".")  ---@cast lnum integer

  if vim.startswith(line, pattern) then
    vim.cmd.normal("dd")  -- delete the line
  else
    local indents = string.rep(" ", vim.fn.indent(vim.fn.prevnonblank(lnum)) or 0)
    vim.fn.append(lnum - 1, indents .. pattern)
    vim.cmd.normal("k")
  end
  -- save file without any events
  if vim.bo.modifiable and vim.bo.modified then
    vim.cmd [[ silent! noautocmd write ]]
  end
end, { buffer = true })
