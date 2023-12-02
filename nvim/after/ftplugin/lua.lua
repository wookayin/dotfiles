-- ftplugin/lua

-- Use tabsize of 2 (ts=2 sts=2 sw=2)
local setlocal = vim.opt_local
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2

-- Formatting
require("config.formatting").create_buf_command("Stylua", "stylua")

-- [[ <F5> or :Build ]]
local is_test = vim.endswith(vim.fn.bufname('%') or '', '_spec.lua')
local lua_package = require("utils.path_utils").path_to_lua_package("%:p")

-- Unit testing (neotest-plenary)
if is_test then
  vim.api.nvim_buf_create_user_command(0, "Build", "echon ':Test' | Test", {})
  vim.api.nvim_buf_create_user_command(0, "Output", "TestOutput", {})

-- do nothing, make :Build use :Make
elseif vim.fn.filereadable('Makefile') == 1 then

-- reload lua package in package.loaded[...]
elseif lua_package then
  vim.api.nvim_buf_create_user_command(0, 'Build', function(opts)
    vim.cmd [[ update ]]
    _require(lua_package)
    vim.notify("Reloaded lua package: " .. lua_package, vim.log.levels.INFO, { title = 'ftplugin/lua' })
  end, { desc = ('Build: reload the lua module (%s)'):format(lua_package), nargs = 0 })

-- source (execute) the lua file as a script
else
  vim.api.nvim_buf_create_user_command(0, 'Build', function(opts)
    vim.cmd [[ update ]]
    -- don't use vim.cmd, to clear lua stacktrace (see RC.should_resource)
    require("utils.rc_utils").exec_keys '<Esc>:source %<CR>'
    vim.notify("Sourced lua script: " .. vim.fn.bufname(), vim.log.levels.INFO, { title = 'ftplugin/lua' })
  end, { desc = 'Build: source as a lua script.', nargs = 0 })
end

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
