-- AutoBuild.lua: Automatic Build or Make upon saving a file.

local M = {}

M.icon = '👀'

-- State variables
M._augroup = vim.api.nvim_create_augroup('AutoBuild', { clear = true })
M._state = false  -- turned off by default


-- Implementation

function M.AutoBuild_handler(event)
  -- Consider only normal buffer and normal files
  local buf = event.buf
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  if vim.bo[buf].filetype == "" then
    return false
  end

  -- Trigger only if the buffer (file) is located under the current directory.
  local absolute_path = vim.fn.fnamemodify(event.match, ':p')
  local cwd = vim.fn.getcwd()
  local is_under_cwd = absolute_path:sub(1, #cwd) == cwd
  if not is_under_cwd then
    return false
  end

  -- Run :Build in a detached mode.
  ---@diagnostic disable-next-line: param-type-mismatch
  vim.schedule(function()
    vim.cmd [[ silent Build ]]
    -- Lualine may not refresh if invoked via script, so force refresh it
    pcall(function()
      require('lualine').refresh()
    end)
  end)
  return true
end

function M.AutoBuild(cmd)
  if cmd == 'toggle' or cmd == '' then
    M.AutoBuild(not M._state)
  elseif cmd == 'status' then
    local msg = M.icon .. " AutoBuild: turned ".. (M._state and "on" or "off")
    vim.notify(msg, vim.log.levels.INFO, { title = 'AutoBuild' })
  elseif cmd == 'off' or cmd == false then
    M._augroup = vim.api.nvim_create_augroup('AutoBuild', { clear = true })
    M._state = false
    M.AutoBuild('status')
  elseif cmd == 'on' or cmd == true then
    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = '*',
      group = M._augroup,
      callback = function(event)
        -- Ignore return value, because returning true will remove the autocmd
        M.AutoBuild_handler(event)
      end
    })
    M._state = true
    M.AutoBuild('status')
  else
    error("Invalid arguments for AutoBuild: " .. cmd)
  end
end

function M.is_enabled()
  return M._state and true or false
end

-- Define commands
vim.api.nvim_create_user_command('AutoBuild',
  function(opts) M.AutoBuild(vim.trim(opts.args)) end,
  {
    nargs = '?',
    complete = function(arglead, cmdline, cursorpos)
      return { 'on', 'off', 'toggle', 'status' }
    end,
  })
return M
