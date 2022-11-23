-- :C, :Config
-- Quickly open config files that are very commonly accessed

local Path = require "plenary.path"

local M = {}
local map = nil  -- computed lazily via build_directory_map

function M.build_directory_map()
  -- Static mappings
  local map = {
    ['vimrc'] = '~/.vim/vimrc',
    ['init.lua'] = '~/.config/nvim/init.lua',
    ['plugins.vim'] = '~/.vim/plugins.vim',
    ['python.vim'] = '~/.vim/after/ftplugin/python.vim',
  }
  -- Add all config/*.lua by scanning the directory
  local config_files = vim.split(vim.fn.glob('~/.config/nvim/lua/config/*.lua'), '\n')
  for _, abspath in ipairs(config_files) do
    local basename = abspath:match '([^/]+)%.lua$'
    map[basename .. '.lua'] = vim.fn.resolve(abspath)  -- resolve symlink
  end
  return map
end

---@diagnostic disable-next-line: unused-local
function M.completion(arglead, cmdline, cursorpos)
  map = map or M.build_directory_map()
  local t = vim.tbl_keys(map)
  table.sort(t)
  return t
end

function M.action(arg)
  map = map or M.build_directory_map()
  local aliases = {
    ['plug'] = 'plugins.vim'
  }
  local file = map[arg] or map[arg .. '.lua'] or map[arg .. '.vim'] or map[aliases[arg]]

  if not file then
    return print("Invalid argument: " .. arg)
  end
  -- Open the file, but switch to the window if exists
  local bufpath = Path:new(file):make_relative(vim.fn.getcwd())
  local c
  if vim.api.nvim_buf_get_name(0) == "" then
    c = [[ edit $path ]]
  else
    c = [[
      try
        vertical sbuffer $path
      catch /E94/
        vsplit $path
      endtry
    ]]
  end
  vim.cmd(string.gsub(c, '%$(%w+)', { path = bufpath }))
end

-- Define commands upon sourcing
vim.api.nvim_create_user_command('Config',
  function(opts) M.action(vim.trim(opts.args)) end,
  {
    nargs = 1,
    complete = M.completion,
  })

vim.fn.CommandAlias('C', 'Config', 'register_cmd' and true)

return M
