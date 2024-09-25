-- ftplugin/lua

-- Use tabsize of 2 (ts=2 sts=2 sw=2)
local setlocal = vim.opt_local
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2

setlocal.colorcolumn = { tostring(100) }

-- Formatting
require("config.formatting").create_buf_command("Stylua", "stylua")
require("config.formatting").maybe_autostart_autoformatting(0, function(project_root)
  local project_has_file = function(x) return vim.loop.fs_stat(project_root .. '/' .. x) ~= nil end
  if project_has_file('.stylua.toml') then
    return { "stylua" }, "`.stylua.toml` detected"
  end
  return false, nil
end)

-- [[ <F5> or :Build ]]
local is_test = vim.endswith(vim.fn.bufname('%') or '', '_spec.lua') ---@type boolean
local lua_package = require("utils.path_utils").path_to_lua_package("%:p") ---@type string?

-- Unit testing (neotest-plenary)
if is_test then
  vim.api.nvim_buf_create_user_command(0, "Build", "echon ':Test' | Test", {})
  vim.api.nvim_buf_create_user_command(0, "Output", "TestOutput", {})

  local project_root = require("utils.path_utils").find_project_root({ ".git" }) ---@type string?
  local filename = assert(vim.fn.bufname('%'))  -- e.g. test/functional/lua/api_spec.lua

  -- exception: neovim tests do not use plenary-busted but the original busted
  -- TODO: make this a part of neotest-plenary or as a separate neotest plugin.
  if vim.endswith(project_root or '', "/neovim") then
    local term = require("utils.term_utils").TermWin.getinstance("lua-neovim-test")
    vim.api.nvim_buf_create_user_command(0, 'Test', function(_)
      -- TODO: detect the current test method with treesitter and run that only
      local testname = filename:match("functional%/") and "functionaltest" or "unittest"
      local cmd = ("TEST_FILE=%s make %s"):format(filename, testname)
      term:run(cmd)
    end, {})
    vim.api.nvim_buf_create_user_command(0, 'TestOutput', function()
      term:focus()
    end, {})
  end

-- do nothing, make :Build use :Make
elseif vim.fn.filereadable('Makefile') == 1 then

else
  -- either :source or _require(...)
  vim.api.nvim_buf_create_user_command(0, 'Build', 'SourceThis', {})
end

--- :SourceThis executes the lua file as a script, or reload as a lua package in package.loaded[...]
local function SourceThis()
  if lua_package then
    _require(lua_package)
    vim.notify(string.format("Reloaded lua package: `%s`", lua_package),
      vim.log.levels.INFO, { title = 'ftplugin/lua', markdown = true })
  else
    vim.cmd [[ source % ]]
    vim.notify(string.format("Sourced lua script: `%s`", vim.fn.bufname()),
      vim.log.levels.INFO, { title = 'ftplugin/lua', markdown = true })
  end
end
vim.api.nvim_buf_create_user_command(0, 'SourceThis', SourceThis, {
  bar = true,
  desc = lua_package and 'Build: source as a lua script.' or 'Build: reload the lua module (%s)'
})

-- Auto-reload hammerspoon config when applicable.
-- ~/.hammerspoon/init.lua or ~/.dotfiles/hammerspoon/init.lua
if vim.fn.has('mac') > 0 and string.match(vim.fn.expand("%:p"), "/hammerspoon/.*%.lua$") then
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = vim.fn.bufnr(),
    group = vim.api.nvim_create_augroup('HammerspoonAutoreload', { clear = false }),
    callback = function()
      os.execute('open -g hammerspoon://reload')
    end
  })
end

-- Make goto-file (gf, ]f) detect lua config files.
setlocal.path:append('~/.dotfiles/nvim/lua')


-- Workaround for neovim#20456: vim syntax for lua files are broken in neovim 0.8+
-- Disable the erroneous $VIMRUNTIME/syntax/lua.vim from loading
vim.b.ts_highlight = 1
require("config.treesitter").setup_highlight("lua")
