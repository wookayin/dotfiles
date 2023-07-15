-- Use tabsize of 2 (ts=2 sts=2 sw=2)

local setlocal = vim.opt_local
setlocal.ts = 2
setlocal.sts = 2
setlocal.sw = 2


-- <F5> or :Make ==> source it, if a (neo)vim config
if string.find(vim.fn.expand("%:p"), "nvim/lua/config/") then
  vim.api.nvim_buf_create_user_command(0, 'Build', function(opts)
    vim.cmd [[
      w
      source %
    ]]
    vim.notify("Sourced " .. vim.fn.bufname())
  end,
  { desc = 'Build: source lua config script.', nargs = 0 })
end


-- Make goto-file (gf, ]f) detect lua config files.
setlocal.path:append('~/.dotfiles/nvim/lua')


-- Workaround for neovim#20456: vim syntax for lua files are broken in neovim 0.8+
-- Disable the erroneous $VIMRUNTIME/syntax/lua.vim from loading
if pcall(require, 'nvim-treesitter') then
  vim.b.ts_highlight = 1
  vim.treesitter.start()
end
