-- Treesitter config
-- https://github.com/nvim-treesitter/nvim-treesitter
-- See $DOTVIM/lua/plugins/treesitter.lua

local M = {}

local has = function(feature) return vim.fn.has(feature) > 0 end

---------------------------------------------------------------------------
--- Entrypoint.
---------------------------------------------------------------------------

-- nvim-treesitter v1.0, the 'main' branch (requires nvim 0.11+)
-- https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
function M.setup_main()
  -- NOTE: $ brew install tree-sitter-cli
  -- TODO: Ensure tree-sitter CLI (0.25.0 or later required) installation;
  -- without it we can't install parsers. But this seems tricky!
  -- However, we don't want to do it every single time on setup because it can slow down startup;

  -- Use a custom install_dir, typically at $HOME/.local/share/nvim/treesitter, other than
  -- the default path ($HOME/.local/share/nvim/site). This is because this 'site' directory is
  -- also a valid &runtimepath that might be used by other NVIM instances with the legacy
  -- treesitter setup. Otherwise, loading nvim-treesitter 1.0+ parsers with incompatible (pre-1.0)
  -- queries and other runtime files will cause a lot of problems and flooding errors.
  local install_dir = vim.fs.joinpath(vim.fn.stdpath('data') --[[@as string]], 'treesitter')
  local VIMRUNTIME = assert(vim.fs.normalize('$VIMRUNTIME'))

  -- v1.0(main): https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#setup
  require('nvim-treesitter').setup {
    install_dir = install_dir,
  }

  -- Automatically essential parsers (if uninstalled yet)
  M.ensure_parsers_installed(M.parsers_to_install)

  -- Regarding install_dir as a &runtimepath:
  -- We want to have the same and reasonable semantics of runtimepath ordering as before;
  -- as described in :help treesitter-query-modeline, so the nvim-treesitter install_dir
  -- should be properly placed somewhere **after** ~/.config/nvim and ~/.local/share/nvim/site
  -- (which is not satisfied by default! it just prepends and thus have a different ordering),
  -- but before ~/.config/nvim/after (the user config).
  -- The current implementation is to put right before $VIMRUNTIME.
  -- See https://github.com/nvim-treesitter/nvim-treesitter/issues/7881
  ---@diagnostic disable-next-line: undefined-field
  local rtp = vim.opt.runtimepath:get() ---@type string[]
  for i, dir in ipairs(rtp) do
    if vim.fs.normalize(dir) == VIMRUNTIME then
      table.insert(rtp, i, install_dir)
      vim.opt.runtimepath = rtp
      break
    end
  end

  -- mkdir -p install_dir
  require('nvim-treesitter.config').get_install_dir('')

  -- Revive some commands that were removed in v1.0!
  vim.api.nvim_create_user_command('TSInstallInfo', function(opts)
    local installed = require('nvim-treesitter.config').get_installed('parsers')
    require('fzf-lua').fzf_exec(installed, {
      complete = false,
      winopts = {
        title = " List of installed TS parsers ",
      },
    })
  end, { nargs = 0, desc = 'List installed treesitter parsers.' })
end

---@deprecated Having for (potentially) temporary fallback
function M.setup_legacy()
  -- for the legacy 'master' (v0.x branch)
  local ts_configs = require("nvim-treesitter.configs")

  ts_configs.define_modules {
    reattach_after_install = M._reattach_after_install
  }

  -- @see https://github.com/nvim-treesitter/nvim-treesitter#modules
  ---@diagnostic disable-next-line: missing-fields
  ts_configs.setup {
    -- Note: parsers are installed at $VIMPLUG/nvim-treesitter/parser/
    ensure_installed = M.parsers_to_install,
    reattach_after_install = { enable = true },

    highlight = {
      -- TreeSitter's highlight/syntax support is yet experimental and has some issues.
      -- It overrides legacy filetype-based vim syntax, and colorscheme needs to be treesitter-aware.
      -- Note: for some ftplugins (e.g. for lua and vim), treesitter highlight might be manually started
      -- see individual ftplugins at ~/.config/nvim/after/ftplugin/
      enable = false,   -- TODO: Enable again when it becomes mature and usable enough.

      -- List of language that will be disabled.
      -- For example, some non-programming-language filetypes (e.g., fzf) should be
      -- explicitly turned off otherwise it will slow down the window.
      disable = { "fzf", "GV", "gitmessengerpopup", "fugitive", "NvimTree" },

      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = { "python" },
    },

    -- Deprecated as of neovim 0.10+ in favor of :InspectTree, only used for neovim <= 0.9
    playground = {
      enable = not has('nvim-0.10'),
      updatetime = 30,
      keybindings = {
        toggle_query_editor = 'o',
        toggle_hl_groups = 'i',
        toggle_injected_languages = 't',
        toggle_anonymous_nodes = 'a',
        toggle_language_display = 'I',
        focus_language = 'f',
        unfocus_language = 'F',
        update = 'R',
        goto_node = '<cr>',
        show_help = '?',
      },
    },
  }
end


function M.setup()
  local use_new_nvim_treesitter = M.is_v1()
  -- use_new_nvim_treesitter = false  -- for debugging

  if use_new_nvim_treesitter then
    M.setup_main()
  else
    vim.notify(
      "nvim-treesitter needs to be on the 'main' branch (>=v1.0); please update the plugin.",
      vim.log.levels.ERROR, { title = "config/treesitter" }
    )
    ---@diagnostic disable-next-line: deprecated
    M.setup_legacy()
  end

  M.setup_keymap()
end

--- Returns true if using nvim-treesitter v1.0 (the 'main' branch).
function M.is_v1()
  return pcall(require, 'nvim-treesitter.config') == true
end

--- Manually setup treesitter highlight (for neovim >= 0.8),
--- can be used in ftplugin/*.lua to manually enable treesitter highlights.
--- Compared against `vim.treesitter.start()`, it adds some more "safe-guards";
--- This works only if treesitter parser has been already installed *through* nvim-treesitter
--- because the neovim core's built-in parser queries may not be compatible (see M.has_parser)
--- TODO: note this guardrail may no longer needed for nvim-treesitter v1.0+ (main).
---       just enough to have vim.treesitter.start(0)?
--- @param lang string
--- @param bufnr? integer
function M.setup_highlight(lang, bufnr)
  vim.validate { lang = { lang, 'string' }, bufnr = { bufnr, 'number', true } }

  if bufnr == 0 or bufnr == nil then
    bufnr = vim.api.nvim_get_current_buf()
  end

  if M.has_parser(lang) then  -- excludes built-in (bundled) parser
    local ok, _ = xpcall(function()
      vim.treesitter.start(bufnr, lang)
      vim.treesitter.query.get(lang, 'highlights')
    end, function(err)
      err = debug.traceback(err, 1)
      M.try_recover_parser_errors(lang, err)
    end)
    return ok and true or false
  else
    -- Maybe start later when parsers become available
    vim.notify_once(
      string.format("Treesitter parser for lang = '%s' does not exist; will auto-install it", lang),
      vim.log.levels.WARN, { title = "config.treesitter" })
    M._reattach_after_install._deferred[bufnr] = lang
    return false
  end
end

-- A hack module to reattach vim.treesitter.start (highlight)
-- as soon as TS parsers are installed asynchronously.
---@deprecated remove it, we need to overhaul the installation logic for nvim-treesitter 1.x
M._reattach_after_install = {
  _deferred = { },
  attach = function(bufnr, lang)
    local _deferred = M._reattach_after_install._deferred
    if _deferred[bufnr] == lang and vim.api.nvim_buf_is_valid(bufnr) then
      vim.treesitter.start(bufnr, lang)
      _deferred[bufnr] = nil
    end
  end,
  attach_all = function()
    local _deferred = M._reattach_after_install._deferred
    for bufnr, lang in pairs(_deferred) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.treesitter.start(bufnr, lang)
      end
    end
    M._reattach_after_install._deferred = {}
  end,
  detach = function(bufnr) end,
}

---------------------------------------------------------------------------
--- Treesitter Parsers (automatic installation and repair)
---------------------------------------------------------------------------

M.parsers_to_install = vim.tbl_flatten {
  false and { -- regular (not applied; using minimal)
    "bash", "bibtex", "c", "cmake", "cpp", "css", "cuda", "dockerfile", "fish", "glimmer", "go", "graphql",
    "html", "http", "java", "javascript", "json", "json5", "jsonc", "latex", "lua",
    "make", "markdown", "markdown_inline", "perl", "python",
    "regex", "rst", "ruby", "rust", "scss", "toml", "tsx", "typescript", "vim", "yaml",
  },
  { -- minimal set of common parsers to install always
    "bash", "comment", "html", "json", "lua", "luadoc", "make", "markdown", "markdown_inline",
    "python", "query", "regex", "vim", "yaml",
    vim.fn.has('nvim-0.9.0') > 0 and "vimdoc" or nil,
  },
}

---More robust version of has_parser, ignoring neovim core's built-in parsers
---and considering ONLY the treesitter parsers installed through nvim-treesitter.
---This is because neovim's default TS parsers can be incompatible with
---runtime query files shipped with nvim-treesitter, causing lots of errors.
---See also "Conflicting parser paths": https://github.com/nvim-treesitter/nvim-treesitter/issues/3970
---@return boolean true if parser is available.
---@return string|nil path of the parser, if applicable; or (optionally) error message if any.
function M.has_parser(lang)
  -- first make sure nvim-treesitter is eagerly loaded so &rtp always contains $VIMPLUG/nvim-treesitter
  pcall(require, "nvim-treesitter")

  if M.is_v1() then
    local parsers_dir = require("nvim-treesitter.config").get_install_dir("parser")
    local parser_path = vim.fs.joinpath(parsers_dir, lang .. '.so')
    if vim.fn.filereadable(parser_path) > 0 then
      return true, parser_path
    else
      return false, nil
    end
  end

  -- Now, the below code is for legacy nvim-treesitter v0.x
  -- `all=false` assumes $VIMPLUG/nvim-treesitter precedes $VIMRUNTIME in &runtimepath.
  local parsers_so = vim.tbl_filter(function(path)
    return vim.startswith(path, os.getenv("VIMPLUG") or '???')  -- ignore built-in parsers
  end, vim.api.nvim_get_runtime_file(('parser/%s.so'):format(lang), false))
  if #parsers_so == 0 then
    return false, nil
  end

  local ok, has_parser = pcall(function()
    -- Note: unlike get_parser, has_parser doesn't perform treesitter parsing.
    return require("nvim-treesitter.parsers").has_parser(lang)
  end)
  if ok then
    return has_parser, nil
  else
    local err = has_parser --[[@as string]]
    return false, err
  end
end

--- Install treesitter parsers if not have been installed yet.
--- Note that this works in an asynchronous manner, so doesn't block until installation is complete.
---@param langs string[]
function M.ensure_parsers_installed(langs)
  if not pcall(require, "nvim-treesitter") then
    return  -- treesitter not available, ignore errors
  end

  vim.validate { langs = { langs, 'table' } }
  if vim.tbl_contains(vim.tbl_map(M.has_parser, langs), false) then
    -- TODO this seems way too complex. can we refactor, or remove the callback/reattach pattern?
    if M.is_v1() then
      -- Get a list of parsers that are uninstalled, and start installing them asynchronously
      local to_install = require("nvim-treesitter.config").norm_languages(langs, { installed = true })
      local task = require("nvim-treesitter").install(to_install)
      task:await(function(err)
        if err then
          vim.notify(err, vim.log.levels.ERROR, { title = 'config.treesitter' })
          return
        end
        -- Execute a callback to reattach all buffers with new treesitter parser installed.
        vim.schedule(function()
          M._reattach_after_install.attach_all()
        end)
      end)
    else
      -- v0.x, nvim-treesitter legacy
      require("nvim-treesitter.install").ensure_installed(langs)
    end
  end
end

local _recover_requested = false

function M.try_recover_parser_errors(lang, err)
  -- This is a fatal, unrecoverable error where treesitter parsers must be re-installed.
  if err and (
    -- see $NEOVIM/src/nvim/lua/treesitter.c query_err_to_string()
    err:match('[Ii]nvalid node type') or
    err:match('[Ii]nvalid field') or
    err:match('[Ii]nvalid capture')
  ) then
  else
    return false  -- Do not handle any other general errors (e.g. parser does not exist)
  end

  -- This can be called more than once; run recovery process only once
  if _recover_requested then return false end
  _recover_requested = true

  -- Treesitter is broken, disable all folding otherwise nvim might hang forever
  vim.opt_global.foldexpr = '0'

  vim.cmd [[
    " workaround: disable TextChangedI autocmds that may cause treesitter errors
    silent! autocmd! cmp_nvim_ultisnips
    silent! autocmd! TreesitterUpdateParsing
  ]]

  -- Try to recover automatically, if nvim-treesitter is still importable.
  local noti_opts = { print = true, timeout = 10000, title = 'config/treesitter', markdown = true }
  vim.notify(("Fatal error on treesitter parsers (see `:messages`), lang = `%s`. " ..
              "Trying to reinstall treesitter parsers...\n\n"):format(lang) ..
             err,
             vim.log.levels.ERROR, noti_opts)

  -- Force-reinstall all treesitter parsers.
  vim.schedule(function()
    vim.defer_fn(function()
      vim.api.nvim_echo({{ "Installing TS Parsers: " .. lang, "MoreMsg" }}, true, {})
      require('nvim-treesitter.install').commands.TSInstallSync["run!"](lang);
      require('nvim-treesitter.install').commands.TSUpdateSync.run();
      vim.notify(("Treesitter parser %s has been re-installed. Please RESTART neovim."):format(lang),
                 vim.log.levels.INFO, noti_opts)
    end, 1000)
  end)

  return true
end

-- Incompatibility between vim.treesitter core API and outdated nvim-treesitter
-- may cause startup errors. Try to inform users with more informative message.
vim.schedule(function()
  if not pcall(require, 'nvim-treesitter') then
    vim.notify("nvim-treesitter is outdated. Please update the plugin (`:Lazy update`).",
      vim.log.levels.ERROR, { title = 'config/treesitter.lua', markdown = true })
  end
end)


--- Manually install by building parsers from a local, devel workspace.
--- Need to first build parser.c manually if there are local changes:
---   $ npm install && node-gyp configure && npm run build && npm run test)
--- e.g.
---   :lua require("config.treesitter").install_parsers_from_devel("luadoc", "~/workspace/dev/tree-sitter-luadoc")
function M.install_parsers_from_devel(lang, dir)
  vim.validate { lang = { lang, 'string' }, dir = { dir, 'string' } }
  dir = vim.fn.expand(dir) --[[ @as string ]]

  -- Glob src/*.c in the directory.
  local cwd = vim.fn.getcwd()
  assert(vim.fn.isdirectory(dir) > 0, "Invalid dir: " .. dir)
  vim.fn.chdir(dir)
  local ok, result = pcall(function()
    return vim.tbl_filter(function(p)
      return #p > 0
    end, vim.split(vim.fn.glob('src/*.c'), '\n'))
  end)
  vim.fn.chdir(cwd)
  if not ok then return error(result) end
  local files = result  --[[ @as string[] ]]
  assert(vim.tbl_count(files) > 0, "parser.c not found.")

  -- Install treesitter parsers.
  local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()
  parser_configs[lang].install_info = {
    url = dir,
    files = files,  -- e.g. { "src/parser.c", "src/scanner.c" },
  }
  vim.notify(string.format("Installing `%s` tree-sitter parser from source:\n\n%s",
    lang, vim.inspect(parser_configs[lang].install_info)))
  vim.cmd.TSInstall { args = { lang }, bang = true }
end



---------------------------------------------------------------------------
--- Custom treesitter queries
---------------------------------------------------------------------------
-- https://github.com/nvim-treesitter/nvim-treesitter#adding-queries
-- "Dynamic" queries depending on project formatting style, etc. can be configured here.
--
-- For static query files, see:
--    $DOTVIM/queries       => "overrides" query files.
--    $DOTVIM/after/queries => "extends" nvim-treesitter's query files
--      (should have the modeline ";; extends", otherwise will be ignored)
--
-- Note that ONLY the first query file in the &runtimepath will be used,
-- ignoring all other query files from plugins (nvim-treesitter) and $VIMRUNTIME
-- unless `;; extend` is used (see :h treesitter-query-modeline).
--
-- Usually runtimepath has an order of:
--   user_config => plugins(nvim-treesitter) => $VIMRUNTIME => user_config/after => ...
--
-- If vim.treesitter.query.set() is used, ANY query files on runtimepath will be ignored.


---------------------------------------------------------------------------
--- Utilities
---------------------------------------------------------------------------

function M.setup_keymap()
  ---@type function(aliasname: string, target: string, { register_cmd?: boolean }
  local cmd_alias = vim.fn.CommandAlias

  -- see $VIMRUNTIME/lua/vim/_inspector.lua
  vim.keymap.set('n', '<leader>tsh', '<cmd>Inspect<CR>')
  vim.keymap.set('n', '<leader>i', '<cmd>Inspect<CR>')

  -- treesitter-playground is deprecated in favor of vim.treesitter.* APIs.
  if vim.fn.has('nvim-0.10') > 0 then
    cmd_alias("TSPlaygroundToggle", "InspectTree", { register_cmd = true })
    cmd_alias("Tree", "InspectTree", { register_cmd = true })

  else  -- nvim < 0.10; fallback to treesitter-playground
    vim.cmd [[ command! InspectTree :TSPlaygroundToggle ]]

    vim.keymap.set('n', '<leader>tsh', '<cmd>TSHighlightCapturesUnderCursor<CR>')
    vim.cmd [[
    augroup TSPlaygroundConfig
      autocmd!
      autocmd FileType tsplayground  setlocal ts=2 sts=2 sw=2
    augroup END
    ]]
  end
end

return M
