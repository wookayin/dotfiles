--- config.pynvim
--- @return fun(): boolean

-- Set the g:python3_host_prog variable to the "current" python in $PATH.
-- pynvim package will be automatically installed if it was missing.

-- This config must be sourced before any first call of has('python3'), py3eval, etc.
-- Note: An invocation of has('python3'), py3, py3eval triggers provider#python3#Call()
-- See also $VIMRUNTIME/autoload/provider/python3.vim that provides python3 host
-- See also $VIMRUNTIME/autoload/provider/pythonx.vim for python host detection logic
-- See also $DOTVIM/ftplugin/python.vim to ensure config.pynvim on startup

-- for future has('python3') like use
local OK_PYNVIM = function() return true end
local NO_PYNVIM = function() return false end

local function echom(msg, hlgroup)
  vim.api.nvim_echo({{ msg, hlgroup }}, true, {})
end
local function warning(msg)
  echom(msg, 'WarningMsg')
end
local function notify_later(msg, level)
  level = level or vim.log.levels.WARN
  vim.schedule(function()
    vim.notify(msg, level, {
      title = '~/.config/nvim/lua/config/pynvim.lua', timeout = 10000,
      markdown = true,
    })
  end)
end

-- If the environment variable $PYTHON3_HOST_PROG is set, use that as the python rplugin host.
if os.getenv('PYTHON3_HOST_PROG') then
  vim.g.python3_host_prog = os.getenv('PYTHON3_HOST_PROG')
end

-- By default, use python3 w.r.t. $PATH as the host python for neovim.
if vim.g.python3_host_prog == "" or not vim.g.python3_host_prog then
  vim.g.python3_host_prog = vim.fn.exepath("python3")
end

if vim.g.python3_host_prog == "" or not vim.g.python3_host_prog then
  warning "ERROR: You don't have python3 on your $PATH. Check $PATH or $SHELL. Most features are disabled."
  return NO_PYNVIM
end

-- Run host python3 to get the version info table (asynchronously).
-- Note: we don't run the provider (py3eval) directly, because it can block the UI.
---@param callback fun(version_info: integer[]|nil)  version_info: e.g., { 3, 11, 5 }; or nil if python3 failed
local function python3_version_async(callback)
  local done = false
  local version_info = nil
  if not vim.system then
    -- neovim < 0.10; just don't do anything as unsupported nvim version was already warned
    return false
  end
  local p = vim.system(
    { vim.g.python3_host_prog, "-W", "ignore", "-c", "import sys; print(list(sys.version_info[:3]))" },
    {}, -- opts
    vim.schedule_wrap(function(result)
      done = true
      if result.code == 0 then
        version_info = vim.F.npcall(vim.json.decode, result.stdout)
      end
      callback(version_info)
    end)
  )
  -- timeout: 2000ms
  vim.defer_fn(function()
    if not done then
      p:kill(9) -- SIGKILL
      callback(nil)
    end
  end, 2000)
end


local function determine_pip_args(pynvim_minimum_version)
  local pip_option = "--verbose --upgrade --force-reinstall "  -- force option is important
  local has_mac = vim.fn.has('mac') > 0

  if not has_mac then  -- for Linux
    -- Use '--user' option when needed
    local py_prefix = vim.fn.trim(vim.fn.system(
      { vim.g.python3_host_prog, "-W", "ignore", "-c", "import sys; print(sys.prefix)" }
    ))
    if py_prefix == "/usr" or py_prefix == "/usr/local" then
      pip_option = pip_option .. "--user "
    end
  end

  pip_option = pip_option .. "--timeout=1 --retries=1 "
  return pip_option .. "'pynvim >= " .. pynvim_minimum_version .. "'"
end

-- This works "synchronously", blocks until the pip command terminates
---@param skip_check boolean?
local function autoinstall_pynvim(skip_check)
  if vim.fn.exepath(vim.g.python3_host_prog) == "" then
    return false
  end
  if vim.system == nil then
    if not skip_check then
      notify_later(
        ("pynvim not installed for " .. vim.g.python3_host_prog .. "\n" ..
        "please run `python3 -m pip install --upgrade pynvim` manually."),
        vim.log.levels.ERROR)
    end
    return false  -- neovim < 0.10, give up and don't do anything fancy
  end
  local verbose = vim.o.verbose

  -- Ensure pynvim >= 0.5.0.
  local function run_pynvim_check(opts)
    vim.system(
      { vim.g.python3_host_prog, "-W", "ignore", "-c", "import pynvim; print(pynvim.__version__)" },
      {}, --opts,
      vim.schedule_wrap(function(result)
        local needs_install = false
        if result.code == 0 then
          local pynvim_version = vim.F.npcall(vim.version.parse, result.stdout) ---@type vim.Version?
          if verbose > 1 then
            vim.notify("pynvim_version = " .. tostring(pynvim_version),
              vim.log.levels.INFO, { title = 'config.pynvim' })
          end
          needs_install = pynvim_version == nil or vim.version.cmp(pynvim_version, '0.5.0') < 0
        else
          -- possibly pynvim is not importable. TODO show error messages
          needs_install = true
        end
        if needs_install then
          opts.pynvim_installer()
        end
      end)
    )
  end
  local function run_pynvim_install()
    notify_later("`pynvim` cannot be imported. " ..
      "Automatically installing pynvim for: `" .. vim.g.python3_host_prog .. "` ...")
    vim.loop.sleep(100)
    vim.cmd [[ redraw! ]]

    local python = vim.g.python3_host_prog
    vim.g.pynvim_install_command = table.concat({
      "(" .. python .. " -c 'import pip' || " .. python .. " -m ensurepip " .. ")",
      python .. " -m pip install " .. determine_pip_args('0.5.0'),
      python .. [[ -c 'import pynvim; print("pynvim:", pynvim.__file__)' ]]
    }, " && ")

    -- Execute pip install pynvim (asynchronous)
    vim.cmd [[ tabnew ]]
    vim.cmd [[ setlocal buftype=nofile bufhidden=hide noswapfile nonumber ]]
    vim.fn.termopen({ 'bash', '-x' ,'-c', vim.g.pynvim_install_command }, {
      on_exit = function(job_id, exit_code)
        if exit_code == 0 then
          local msg = "Successfully installed pynvim. Please restart neovim."
          echom(msg, "MoreMsg")
          notify_later(msg, vim.log.levels.INFO)
        else
          local msg = "Failed to install pynvim on " .. assert(vim.g.python3_host_prog)
          warning(msg)
          notify_later(msg, vim.log.levels.ERROR)
        end
      end
    })
    -- TODO termopen() deprecated in nvim 0.11, use jobstart(…, { term=true }) instead.
  end

  run_pynvim_check { pynvim_installer = run_pynvim_install }
end

--- Check python version and show warning messages (asynchronously) if requirements are not met.
--- Runs asynchronously, to prevent neovim from freezing while an external process is running.
local function python3_version_check()
  local verbose = vim.o.verbose
  python3_version_async(function(py_version)
    local ok = py_version and (
      py_version[1] > 3 or
      py_version[1] == 3 and py_version[2] >= 7  -- requires python 3.7+
    )
    if ok then
      if verbose >= 1 then
        vim.notify(vim.inspect({
          python3_host_prog = vim.g.python3_host_prog,
          python3_version = vim.inspect(py_version)
        }), vim.log.levels.INFO, { title = 'config.pynvim' })
      end
      return
    end

    -- show warning messages
    -- TODO validate this works actually
    local msg
    if py_version then
      msg = string.format("Your python3 version (%s) is too old;", table.concat(py_version, "."))
    elseif vim.fn.filereadable(vim.g.python3_host_prog) == 0 then
      msg = ("python3_host_prog executable does not exist: %s"):format(vim.g.python3_host_prog)
    else
      msg = ("python3 version cannot be detected.")  -- TODO: attach stderr msg or more context
    end
    do
      warning(msg .. " g:python3_host_prog = " .. vim.g.python3_host_prog)
      msg = msg .. '\n' .. "python 3.7+ is required. Most features are disabled.\n"
      msg = msg .. '\n' .. "g:python3_host_prog = " .. vim.g.python3_host_prog
      msg = msg .. '\n' .. "exepath = " .. vim.fn.exepath(vim.g.python3_host_prog)
      notify_later(msg)
    end
  end)
end

if vim.F.npcall(vim.fn.py3eval, "1") ~= 1 then
  -- python3 host has failed to load. Run diagnostics.
  python3_version_check()

  -- pynvim is missing, try installing it (blocking!)
  xpcall(autoinstall_pynvim, function(err)
    local msg = debug.traceback(err, 1)
    vim.notify(msg, vim.log.levels.ERROR)
  end)

  -- Disable autocmds from already-generated rplugins manifest,
  -- which will emit annoying errors on CmdlineEnter, VimLeave, etc.
  vim.schedule(function()
    xpcall(function()
      local groups = vim.fn.split(vim.fn.execute('augroup'))
      for _, augroup in ipairs(groups) do
        if vim.startswith(augroup, "RPC_DEFINE_AUTOCMD_GROUP_") then
          vim.cmd(([[ autocmd! %s ]]):format(augroup))
        end
      end
    end, function(err)
      local msg = err -- no need stacktrace here
      vim.api.nvim_err_writeln(msg)
    end)
  end)

  -- Still need to disable python3 provider, it's already broken
  vim.g.loaded_python3_provider = 0  -- Disable has('python3'), see neovim#32696
  return NO_PYNVIM
else
  -- pynvim already there and probably working fine,
  -- check versions lazily and asynchronously without blocking nvim
  vim.schedule(function()
    python3_version_check()
    -- TODO do not try installing pynvim if python3 version is too old.
    autoinstall_pynvim(true)
  end)
end

return OK_PYNVIM
