--- config/pynvim
---@return fun(): boolean
-- Set the g:python3_host_prog variable to path to python3 in $PATH.
-- pynvim package will be automatically installed if it was missing.

-- This config must be sourced before any first call of has('python3'), py3eval, etc.
-- Note: An invocation of has('python3'), py3, py3eval triggers provider#python3#Call()
-- See also $VIMRUNTIME/autoload/provider/python3.vim that provides python3 host
-- See also $VIMRUNTIME/autoload/provider/pythonx.vim for python host detection logic
-- See also $DOTVIM/ftplugin/python.vim to ensure config.pynvim on startup

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
    vim.notify(msg, level, {title = '~/.config/nvim/lua/config/pynvim.lua', timeout = 10000,
  })
  end)
end


-- Always python3 w.r.t. $PATH as the host python for neovim.
vim.g.python3_host_prog = vim.fn.exepath("python3")

if vim.g.python3_host_prog == "" or not vim.g.python3_host_prog then
  warning "ERROR: You don't have python3 on your $PATH. Check $PATH or $SHELL. Most features are disabled."
  return NO_PYNVIM
end

-- Note: should not use py3eval here because python3 provider is slow, and may not work!
---@type fun(): table[]  returns a version tuple, e.g., { 3, 11, 5 }
local python3_version = setmetatable({ _version = nil }, { __call = function(self)
  if self._version then
    return self._version
  end
  local s = system(vim.g.python3_host_prog .. " -W ignore -c 'import sys; print(list(sys.version_info)[:3])' 2>/dev/null")
  self._version = vim.F.npcall(vim.json.decode, s)
  return self._version
end}) --[[@as fun()]]


local function determine_pip_args()
  local pip_option = "--upgrade --force-reinstall "  -- force option is important
  local has_mac = vim.fn.has('mac') > 0

  if not has_mac then  -- for Linux
    -- Use '--user' option when needed
    local py_prefix = system("python3 -c 'import sys; print(sys.prefix)' 2>/dev/null")
    if py_prefix == "/usr" or py_prefix == "/usr/local" then
      pip_option = pip_option .. "--user "
    end
  end

  if python3_version()[2] >= 12 then  -- python 3.12
    return pip_option .. [[ 'pynvim @ git+https://github.com/neovim/pynvim' ]]
  end
  return pip_option .. "pynvim"
end

-- This works "synchronously", blocks until the pip command terminates
---@return boolean whether installation is successful
local function autoinstall_pynvim()
  -- Ensure pynvim >= 0.4.0.
  local python3_neovim_version = system(assert(vim.g.python3_host_prog) ..
    " -W ignore -c 'import pynvim; print(pynvim.VERSION.minor)' 2>/dev/null")
  local needs_install = tonumber(python3_neovim_version) == nil or tonumber(python3_neovim_version) < 4
  if not needs_install then
    return false
  end

  vim.api.nvim_echo({{ "Automatically installing pynvim for: " .. vim.g.python3_host_prog .. " ...", "Moremsg" }}, true, {})
  vim.loop.sleep(100)
  vim.cmd [[ redraw! ]]

  vim.g.pynvim_install_command = table.concat({
    vim.g.python3_host_prog .. " -m ensurepip ",
    vim.g.python3_host_prog .. " -m pip install " .. determine_pip_args(),
    vim.g.python3_host_prog .. [[ -c 'import pynvim; print("pynvim:", pynvim.__file__)' ]]
  }, " && ")

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
    echom g:pynvim_install_command
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
  local py_version = python3_version()  ---@type integer[]

  if not py_version or (
    py_version[1] < 3 or
    py_version[1] == 3 and py_version[2] < 6  -- checks if version < 3.6
  ) then
    local msg = string.format("Your python3 version (%s) is too old; ",
      table.concat(py_version or { "unknown" }, ".") )
    warning(msg .. vim.g.python3_host_prog)
    msg = msg .. '\n' .. "python 3.6+ is required. Most features are disabled."
    msg = msg .. '\n\n' .. "g:python3_host_prog = " .. vim.g.python3_host_prog
    notify_later(msg)
  end
end

-- Make a dummy call first, to workaround a bug neovim/neovim#14438 and neovim/pynvim#496
-- At this point the python3 provider will be loaded.
-- NOTE: This takes some init time (~50ms), but is necessary otherwise other python plugins will fail
vim.fn.py3eval("1")  -- TODO: Remove this workaround once pynvim 0.5 is out.

if vim.fn.py3eval("1") ~= 1 then
  python3_version_check()

  -- pynvim is missing, try installing it
  local success = vim.F.ok_or_nil(xpcall(autoinstall_pynvim, function(err)
    local msg = debug.traceback(err, 1)
    vim.notify(msg, vim.log.levels.ERROR)
  end))

  do  -- Disable autocmds from already-generated rplugins manifest, which will emit annoying errors
      -- see $VIMRUNTIME/autoload/remote/define.vim
    vim.cmd [[
      function! remote#define#AutocmdBootstrap(...)
      endfunction
      function! remote#define#FunctionBootstrap(...)
      endfunction
      function! remote#define#CommandBootstrap(...)
      endfunction
    ]]
  end

  -- Still need to disable python3 provider, it's already broken
  vim.g.loaded_python3_provider = 1  -- Disable has('python3')
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
