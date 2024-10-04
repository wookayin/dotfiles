-- config/build.lua
-- Build system configuration

local M = {}

function M.setup_asyncrun()
  local group_asyncrun_nvim = vim.api.nvim_create_augroup('asyncrun_nvim', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'AsyncrunJobStart',
    group = group_asyncrun_nvim,
    callback = function(e)
      vim.fn['OnAsyncRunJobStart'](e.data.job)  -- see ~/.vimrc
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    pattern = { 'AsyncrunJobSuccess', 'AsyncrunJobFail' },
    group = group_asyncrun_nvim,
    callback = function(e)
      local job = e.data or nil
      vim.g.asyncrun_status = vim.endswith(e.match, "Success") and "success" or "fail" -- XXX adapter
      vim.fn['OnAsyncRunJobFinished'](e.data.job)  -- see ~/.vimrc
    end,
  })
end


return M
