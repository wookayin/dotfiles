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

  -- Note: this config variable must be set before any ftplugin
  vim.g.vimtex_compiler_latexmk = {
    continuous = 0,  -- Do not use the -pvc mode.
  }
end

--- Configs that can be set *after* the plugin is loaded.
function M.setup()
  M._setup_compiler()
  M._setup_viewer()
end

-- Register :Build command for the current buffer, see ftplugin/{tex,bib}
function M.setup_compiler_commands()
  assert(vim.tbl_contains({'tex', 'bib', 'bibtex'}, vim.bo.filetype))

  -- <F5> :Build (single shot compilation)
  vim.api.nvim_buf_create_user_command(0, 'Build', function(opts)
    vim.fn['vimtex#compiler#compile']()
  end, { nargs = '?', desc = 'Build with Vimtex' })

  -- <F6> Copen (quickfix)
  -- <M-F6> VimtexCompileOutput (raw log)
  -- <F7> VimtexView + forward-search
  vim.keymap.set({'n', 'i'}, '<M-F6>', '<cmd>VimtexCompileOutput<CR>', { buffer = true })
  vim.keymap.set({'n', 'i', 'v'}, '<F7>', '<Plug>(vimtex-view)', { remap = true, buffer = true })
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
    -- notify('Continuous auto-build started. Useful commands: :VimtexStop to stop')
    M._update_job_status('running')
  end)
  -- autocmd('VimtexEventCompiling', function()  -- for the continuous mode
  --   M._update_job_status('running')
  -- end)
  autocmd('VimtexEventCompileSuccess', function()
    M._update_job_status('success')
    vim.defer_fn(function() M._update_job_status('') end, 1000)
    vim.fn['vimtex#view#view']()  -- trigger :VimtexView
    update_sign_from_qf()
  end)
  autocmd('VimtexEventCompileFailed', function()
    M._update_job_status('failed')
    vim.defer_fn(function() M._update_job_status('') end, 2000)
    update_sign_from_qf()
  end)

  _G.vimtex_status = M.vimtex_status

  -- Make vimtex compiler silent, since we now have statusline integration
  vim.g.vimtex_compiler_silent = true
end

M._vimtex_compiler_jobs = { status = '' }
M._update_job_status = function(status)
  M._vimtex_compiler_jobs.status = (status or '')
end

-- statusline integration (TODO: avoid using global variables)
_G.vimtex_jobs = M._vimtex_compiler_jobs


-- in macOS, use Skim as the default LaTeX PDF viewer (for vimtex)
-- for :Vimtexview, move Skim's position to where the cursor currently points to.
function M._setup_viewer()
  if vim.fn.has('mac') > 0 then
    local has_texshop = function()
      return vim.fn.executable('texshop') > 0 and (
        vim.fn.isdirectory('/Applications/TeX/TeXShop.app') > 0 or
        vim.fn.isdirectory('/Applications/TeXShop.app') > 0)
    end
    local use_texshop = function()
      -- TexShop: ~/.dotfiles/bin/texshop
      vim.g.vimtex_view_method = 'general'
      vim.g.vimtex_view_general_viewer = 'texshop'
    end

    local has_skim = function()
      return vim.fn.isdirectory('/Applications/Skim.app') > 0
    end
    local use_skim = function()
      -- Skim.app (with TexSync)
      -- Note: to use inverse search (Shift+Cmd+Click) from Skim, see :help VimtexInverseSearch
      --   nvim --headless -c "VimtexInverseSearch %line '%file'"
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_view_skim_sync = 1  -- Forward search after successful build
      vim.g.vimtex_view_skim_reading_bar = 1 -- Highlight the current line
      vim.g.vimtex_view_skim_activate = 0  -- Do not steal the focus
    end

    -- Use Skim as a preferred latex viewer.
    -- Tip for Skim: Use "Single Page" display mode to avoid flickering
    if has_skim() then use_skim()
    elseif has_texshop() then use_texshop()
    end
  end
end

return M
