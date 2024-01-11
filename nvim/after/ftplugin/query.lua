-- ftplugin/query.lua


-- Custom commands

--- :ExtendsOpen
vim.api.nvim_buf_create_user_command(0, 'ExtendsOpen', function(opts)
  local path = vim.fn.expand("%:p")  --[[ @as string ]]

  -- e.g. "queries/lua/highlights.scm"
  local rpath = path:match("nvim/after/(.-)$")
  if rpath then
    assert(os.getenv('VIMPLUG'))
    local target = vim.fn.expand("$VIMPLUG/nvim-treesitter/" .. rpath)
    vim.cmd.edit { args = { target } }
  else
    vim.api.nvim_err_writeln("Not a nvim config query file.")
  end
end, { desc = "Open the query file in nvim-treesitter which this ';;extends' from)" })
