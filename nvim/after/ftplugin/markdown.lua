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


-- GFM markdown preview using grip
-- (pip install grip)
vim.api.nvim_buf_create_user_command(0, 'Grip', function(opts)
  local win = vim.api.nvim_get_current_win()
  local exitcode = nil
  vim.cmd [[ botright 7new ]]
  vim.cmd [[ setlocal winfixheight ]]
  vim.fn.termopen({ "grip", vim.fn.expand('%'), "0.0.0.0" }, {
    on_exit = function(job_id, data, event)
      exitcode = data
    end,
  })
  vim.api.nvim_set_current_win(win)
  vim.cmd.stopinsert()  -- workaround for autocmd+terminal bug

  if vim.ui.open and os.getenv('SSH_CONNECTION') == nil then
    vim.defer_fn(function()
      if exitcode == nil or exitcode == 0 then
        vim.ui.open('http://localhost:6419/')
      end
    end, 200)
  end
end, { nargs = 0 })

-- Markdown headings-
vim.cmd [[
  nnoremap <buffer> <leader>1 m`yypVr=``
  nnoremap <buffer> <leader>2 m`yypVr-``
  nnoremap <buffer> <leader>3 m`^i### <esc>``4l
  nnoremap <buffer> <leader>4 m`^i#### <esc>``5l
  nnoremap <buffer> <leader>5 m`^i##### <esc>``6l
]]
