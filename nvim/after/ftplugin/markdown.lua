-- ftplugin/markdown

local setlocal = vim.opt_local

setlocal.expandtab = true
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2

setlocal.iskeyword:append({'_', ':'})

-- do not use conceal (for now)
setlocal.conceallevel = 0

-- Use treesitter highlight.
require("config.treesitter").ensure_parsers_installed { "markdown" }
require("config.treesitter").setup_highlight("markdown")

-- Use spell checking (only for normal files)
if vim.bo.buftype == "" then
  setlocal.spell = true
end


-- Markdown preview using markdown-preview
-- Install: npm install -g @mryhryki/markdown-preview
vim.api.nvim_buf_create_user_command(0, 'Preview', function(opts)
  local function run_preview(cmd)
    local win = vim.api.nvim_get_current_win()
    local exitcode = nil
    vim.cmd [[ botright 7new ]]
    vim.cmd [[ setlocal winfixheight ]]
    vim.fn.termopen(cmd, {
      on_exit = function(job_id, data, event)
        exitcode = data
      end,
    })
    vim.api.nvim_set_current_win(win)
    vim.cmd.stopinsert()  -- workaround for autocmd+terminal bug
  end

  local filepath = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':~:.')
  if false and vim.fn.executable('markdown-preview') == 1 then
    run_preview({ 'markdown-preview', '-f', filepath })
  else
    vim.ui.select({ 'Yes', 'No' }, {
      prompt = '`markdown-preview` CLI not found. Run via npx @mryhryki/markdown-preview?',
    }, function(choice)
      if choice and choice:lower() == 'y' then
        run_preview({ 'npx', '@mryhryki/markdown-preview', '-f', filepath })
      end
    end)
  end
end, { nargs = 0 })

-- Markdown headings-
vim.cmd [[
  nnoremap <buffer> <leader>1 m`^i# <esc>``2l
  nnoremap <buffer> <leader>2 m`^i## <esc>``3l
  nnoremap <buffer> <leader>3 m`^i### <esc>``4l
  nnoremap <buffer> <leader>4 m`^i#### <esc>``5l
  nnoremap <buffer> <leader>5 m`^i##### <esc>``6l
]]

-- buffer-local keymap
vim.keymap.set('n', '<M-i>', '<cmd>Inspect<CR>', { buffer = true, desc = ':Inspect' })
vim.keymap.set('x', '<leader>|', 'ga*|', { buffer = true, remap = true, desc = 'Align markdown table' })
