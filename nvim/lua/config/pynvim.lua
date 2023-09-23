--- config/pynvim
---@return fun(): boolean
-- Set the g:python3_host_prog variable to path to python3 in $PATH.
-- pynvim package will be automatically installed if it was missing.

vim.g.python3_host_prog = ''

-- for future has('python3') like use
local OK_PYNVIM = function() return true end
local NO_PYNVIM = function() return false end

-- Utility: Run a shell command and capture the output.
local function system(command)
  local file = assert(io.popen(command, 'r'))
  local output = file:read('*all'):gsub("%s+", "")
  file:close()
  return output
end

-- Utility: echomsg with optional highlight.
local function echom(msg, hlgroup)
  -- TODO: neovim does not retain highlight unlike :echom does, see neovim#13812
  -- vim.api.nvim_echo({{ msg, hlgroup }}, true, {})
  hlgroup = hlgroup or 'Normal'
  msg = vim.fn.escape(msg, '"')
  local cmd = [[echohl $hlgroup | echomsg "$msg" | echohl None]]
  cmd = cmd:gsub('%$(%w+)', { msg = msg, hlgroup = hlgroup })
  vim.cmd(cmd)
end
local function warning(msg)
  return echom(msg, 'WarningMsg')
end
local function notify_later(msg, level)
  level = level or vim.log.levels.WARN
  vim.schedule(function()
    vim.notify(msg, level, {title = '~/.config/nvim/lua/config/pynvim.lua', timeout = 10000})
  end)
end

-- Use python3 as per $PATH as the host python for neovim.
if vim.fn.executable("python3") > 0 then
  vim.g.python3_host_prog = vim.fn.exepath("python3")
else
  warning "ERROR: You don't have python3 on your $PATH. Check $PATH or $SHELL. Most features are disabled."
  return NO_PYNVIM
end


local function determine_pip_options()
  local pip_option = ""
  local has_mac = vim.fn.has('mac') > 0
  if has_mac then
    -- Use '--user' option when needed
    local py_prefix = system("python3 -c 'import sys; print(sys.prefix)' 2>/dev/null")
    if py_prefix == "/usr" or py_prefix == "/usr/local" then
      pip_option = "--user"
    end
    pip_option = pip_option .. " --upgrade --ignore-installed"

    -- mac: Force greenlet to be compiled from source due to potential architecture mismatch (pynvim#473)
    if has_mac then
      pip_option = pip_option .. ' --no-binary greenlet'
    end
    return pip_option
  end
  return pip_option
end

-- This works "synchronously", blocks until the pip command terminates
---@return boolean whether installation is successful
local function autoinstall_pynvim()
  -- Ensure pynvim >= 0.4.0.
  local python3_neovim_version = system(assert(vim.g.python3_host_prog) .. " -c 'import pynvim; print(pynvim.VERSION.minor)' 2>/dev/null")
  local needs_install = tonumber(python3_neovim_version) == nil or tonumber(python3_neovim_version) < 4
  if not needs_install then
    return false
  end

  vim.api.nvim_echo({{ "Automatically installing pynvim for: " .. vim.g.python3_host_prog .. " ...", "Moremsg" }}, true, {})
  vim.loop.sleep(100)
  vim.cmd [[ redraw! ]]

  vim.g.pynvim_install_command = (
    vim.g.python3_host_prog .. " -m ensurepip && " ..
    vim.g.python3_host_prog .. " -m pip install " .. determine_pip_options() .. " " .. "pynvim"
  )

  -- !shell execution cannot have a fine-grained control, so we use jobstart() or termopen()
  _G.pynvim_handler = setmetatable({
    console = '',
    __call = function(self, job_id, lines, event)
      -- On stdout line streamed, inform users what's going on
      if event == 'stdout' then
        lines = table.concat(lines, '\n')
        for _, line in pairs(vim.split(lines, '\n')) do
          print(line)
          -- Note: nvim_echo doesn't flush despite redraw, and the overflowing lines are annoying
          -- vim.api.nvim_echo({{ line, 'MoreMsg' }}, true, {})
          vim.cmd [[ redraw! ]]
        end
        self.console = self.console .. lines
      -- On stderr, collect and show at once
      elseif event == 'stderr' then
        lines = table.concat(lines, '\n')
        self.console = self.console .. lines
      end
    end,
    --- Show stderr messages in a scratchpad
    show_stderr = vim.schedule_wrap(function(self)
      if #self.console > 0 then
        vim.cmd [[ tabnew ]]
        vim.cmd [[ setlocal buftype=nofile bufhidden=hide noswapfile nonumber ]]
        vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(self.console, '\n'))
        vim.api.nvim_buf_set_name(0, vim.g.pynvim_install_command)
        vim.bo[0].filetype = 'log'  -- Use some highlighting
      end
    end),
  }, { __call = function(self, ...) return self:__call(...) end })

  vim.cmd [[
    " Note: Unlike jobstart(), termopen() cannot use on_stderr (neovim/neovim#23660)
    let jobid = jobstart(['bash', '-x', '-c', g:pynvim_install_command], {
        \  'on_stdout': { j,d,e -> v:lua.pynvim_handler(j,d,e) },
        \  'on_stderr': { j,d,e -> v:lua.pynvim_handler(j,d,e) },
        \})
    let retcode = jobwait([jobid])[0]
    if retcode == -2
      call v:lua.pynvim_handler(jobid, ['ERROR: Interrupted'], 'stderr')
    endif
    exec printf('silent !exit %d', retcode)
  ]]

  if vim.v.shell_error == 0 then
    echom("Successfully installed pynvim. Please restart neovim.", "MoreMsg")
    notify_later("Successfully installed pynvim. Please restart neovim.", "info")
    _G.pynvim_handler = nil
    return true
  else
    _G.pynvim_handler:show_stderr()
    warning("Failed to install pynvim on " .. assert(vim.g.python3_host_prog))
    notify_later("Failed to install pynvim on " .. assert(vim.g.python3_host_prog))
    return false
  end
end

-- python version check
local function python3_version_check()
  if vim.fn.py3eval('sys.version_info < (3, 6)') then
    local py_version = vim.fn.py3eval('".".join(str(x) for x in sys.version_info[:3])')
    if py_version == 0 then py_version = "cannot read" end
    local msg = string.format("Your python3 version (%s) is too old; ", py_version)
    warning(msg)
    msg = msg .. '\n' .. "python 3.6+ is required. Most features are disabled."
    msg = msg .. '\n\n' .. "g:python3_host_prog = " .. vim.g.python3_host_prog
    notify_later(msg)
    return false
  end
  return true
end

-- Make a dummy call first, to workaround a bug neovim#14438
-- At this point the python3 provider will be loaded.
-- NOTE: This takes some init time (~50ms), but is necessary otherwise other python plugins will fail
vim.fn.py3eval("1")

if vim.fn.py3eval("1") ~= 1 then
  -- pynvim is missing, try installing it
  local success = vim.F.ok_or_nil(xpcall(autoinstall_pynvim, function(err)
    local msg = debug.traceback(err, 1)
    vim.notify(msg, vim.log.levels.ERROR)
  end))

  -- Still need to disable python3 provider, it's already broken
  return NO_PYNVIM
else
  -- pynvim already there, check versions lazily
  vim.schedule(function()
    autoinstall_pynvim()
    python3_version_check()
  end)
end

-- Return true iff python3 is available.
-- Instead of calling has('python3'), use require('config.pynvim').
return OK_PYNVIM
