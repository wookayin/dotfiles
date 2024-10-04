-- :C, :Config
-- Quickly open config files that are very commonly accessed

local Path = require "plenary.path"

local M = {}
local map = nil  -- computed lazily via build_directory_map

function M.build_directory_map()
  -- Static mappings
  local map = {
    ['vimrc'] = '~/.vim/vimrc',
    ['init.lua'] = vim.fn.expand('$DOTVIM/init.lua'),
  }
  local function _scan(glob_pattern, prefix)
    local files = vim.split(vim.fn.glob(glob_pattern), '\n')
    prefix = prefix or ''
    for _, abspath in ipairs(files) do
      local filename = abspath:match ('([^/]+)$')  -- strip the dir part
      map[prefix .. filename] = vim.fn.resolve(abspath)  -- resolve symlink
    end
  end
  -- Scan and add common config and plugin files
  _scan('~/.config/nvim/lua/config/*.lua')
  _scan('~/.config/nvim/lua/plugins/*.lua', 'plugins/')
  _scan('~/.config/nvim/after/ftplugin/*.lua', 'ftplugin/')
  _scan('~/.config/nvim/after/ftplugin/*.vim', 'ftplugin/')
  _scan('~/.config/nvim/colors/*.vim', 'colors/')
  return map
end

---@diagnostic disable-next-line: unused-local
function M.completion(arglead, cmdline, cursorpos)
  map = map or M.build_directory_map()
  local t = vim.tbl_keys(map)
  table.sort(t, function(e1, e2)
    -- Sort by depth and then lexicographically.
    local d1 = select(2, string.gsub(e1, '/', ''))
    local d2 = select(2, string.gsub(e2, '/', ''))
    if d1 ~= d2 then return d1 < d2 end
    return e1 < e2
  end)
  return t
end

function M.action(arg)
  map = map or M.build_directory_map()
  local aliases = {
    ['plug'] = 'plugins.lua',
    ['lazy'] = 'plugins.lua',
    ['ide'] = 'plugins/ide.lua',
    ['theme'] = 'colors/xoria256-wook.vim',
    ['color'] = 'colors/xoria256-wook.vim',
  }
  local file = map[arg] or map[arg .. '.lua'] or map[arg .. '.vim'] or map[aliases[arg]]
  if arg == 'ftplugin/' or arg == 'ftplugin' then
    file = ('~/.config/nvim/after/ftplugin/%s%s'):format(vim.bo.filetype,
      vim.bo.filetype ~= "" and ".lua" or "")
  end

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
vim.fn.CommandAlias('Ftplugin', 'Config ftplugin/<C-R>=EatWhitespace()<CR>', { register_cmd = true })
vim.fn.CommandAlias('ftplugin', 'Config ftplugin/<C-R>=EatWhitespace()<CR>', { register_cmd = false })

return M
