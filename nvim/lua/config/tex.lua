-- config for latex and vimtex
-- See doc: $VIMPLUG/vimtex/doc/vimtex.txt
-- See also ~/.config/nvim/after/ftplugin/tex.lua
-- See also ~/.config/nvim/after/ftplugin/tex.vim

local M = {}

-- Options that need to be set before packadd.
-- :help vimtex-options
function M.init()
  -- Always prefer latex instead of plaintex, etc. (:h vimtex-tex-flavor)
  vim.g.tex_flavor = 'latex'

  -- Do not open quickfix when there are warnings only but no errors
  vim.g.vimtex_quickfix_open_on_warning = 0

  -- Use treesitter highlights for tex, see $DOTVIM/after/syntax/tex.vim
  vim.g.vimtex_syntax_enabled = 0

  -- suppress version warning
  vim.g.vimtex_disable_version_warning = 1

  -- Disable neovim's popup window for user prompt,
  -- the popup window blocks the UI in an unpleasant way
  vim.g.vimtex_ui_method = {
    confirm = 'legacy',
    input = 'legacy',
    select = 'legacy',
  }
end

--- Configs that can be set after the plugin is loaded.
function M.setup()
  M._setup_compiler()
  M._setup_viewer()
end

-- Register :Build command for the current buffer, see ftplugin/{tex,bib}
function M.setup_compiler_commands()
  -- :Build
  vim.api.nvim_buf_create_user_command(0, 'Build', function(opts)
    vim.fn['vimtex#compiler#start']()
  end, { nargs = '?', desc = 'Build with Vimtex (continuous build mode)' })
  vim.keymap.set('n', '<S-F5>', 'VimtexStop', { buffer = true, remap = false })
end

-- Bind vimtex's compiler autocmd events, so it can play nicely with other plugins
function M._setup_compiler()

  -- Utilities
  local vimtex_event = vim.api.nvim_create_augroup('vimtex_event', { clear = true })
  local autocmd = function(event_name, callback)
    vim.api.nvim_create_autocmd('User', {
      pattern = event_name,
      group = vimtex_event,
      callback = function() callback() end,
    })
  end
  local notify = function(msg)
    return vim.notify(msg, vim.log.levels.INFO, { title = 'config/tex.lua' })
  end

  -- Update diagnostics from quickfix result (compiler error messages),
  -- which can be triggered when vimtex compilation is done
  local update_sign_from_qf = vim.schedule_wrap(function()
    vim.api.nvim_exec_autocmds('QuickFixCmdPost', { pattern = 'make',
      modeline = false, data = nil })
  end)

  -- Integration with statusline
  autocmd('VimtexEventCompileStarted', function()
    notify('Continuous auto-build started. Useful commands: :VimtexStop to stop')
  end)
  autocmd('VimtexEventCompiling', function()
    M._vimtex_compiler_jobs.status = 'running'
  end)
  autocmd('VimtexEventCompileSuccess', function()
    M._vimtex_compiler_jobs.status = 'success'
    vim.defer_fn(function() M._vimtex_compiler_jobs.status = '' end, 1000)
    vim.fn['vimtex#view#view']()
    update_sign_from_qf()
  end)
  autocmd('VimtexEventCompileFailed', function()
    M._vimtex_compiler_jobs.status = 'failed'
    vim.defer_fn(function() M._vimtex_compiler_jobs.status = '' end, 2000)
    update_sign_from_qf()
  end)

  _G.vimtex_status = M.vimtex_status

  -- Make vimtex compiler silent, since we now have statusline integration
  vim.g.vimtex_compiler_silent = true
end

M._vimtex_compiler_jobs = { status = '' }

-- statusline integration
function M.vimtex_status()
  local icons = {
    running = '⏳',
    success = '✅',
    failed = '❌',
    [''] = '✍️ ',
  }
  local ret = ""
  for _, data in ipairs(vim.fn['vimtex#state#list_all']()) do
    local jobid = data.compiler.job
    local is_running = jobid and vim.fn.jobpid(jobid) > 0
    if is_running then
      ret = ret .. (icons[M._vimtex_compiler_jobs.status] or icons[''])
    end
  end
  return ret
end

-- in macOS, use Skim as the default LaTeX PDF viewer (for vimtex)
-- for :Vimtexview, move Skim's position to where the cursor currently points to.
function M._setup_viewer()
  if vim.fn.has('mac') > 0 then
    local has_texshop = (
      vim.fn.isdirectory('/Applications/TeX/TeXShop.app') > 0 or
      vim.fn.isdirectory('/Applications/TeXShop.app') > 0
    )
    if vim.fn.executable('texshop') > 0 and has_texshop then
      -- ~/.dotfiles/bin/texshop
      vim.g.vimtex_view_general_viewer = 'texshop'
    else
      -- Skim.app
      vim.g.vimtex_view_general_viewer = '/Applications/Skim.app/Contents/SharedSupport/displayline'
      vim.g.vimtex_view_general_options = '-r -g @line @pdf @tex'
    end
  end
end

return M
