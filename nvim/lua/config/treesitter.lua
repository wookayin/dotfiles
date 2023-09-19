-- Treesitter config
-- https://github.com/nvim-treesitter/nvim-treesitter
-- See $DOTVIM/lua/plugins/treesitter.lua

local M = {}

-- Compatibility layer for neovim < 0.9.0 (see neovim#22761)
if not vim.treesitter.query.set then
  ---@diagnostic disable-next-line: deprecated
  vim.treesitter.query.set = require("vim.treesitter.query").set_query
end

---------------------------------------------------------------------------
-- Entrypoint.
---------------------------------------------------------------------------

function M.setup()
  local ts_configs = require("nvim-treesitter.configs")

  -- @see https://github.com/nvim-treesitter/nvim-treesitter#modules
  ---@diagnostic disable-next-line: missing-fields
  ts_configs.setup {
    ensure_installed = M.parsers_to_install,

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
      enable = true,
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

  -- Folding support
  vim.o.foldmethod = 'expr'
  vim.o.foldexpr = 'nvim_treesitter#foldexpr()'
  M.setup_custom_queries()

  M.setup_keymap()
end

--- Manually setup treesitter highlight (for neovim >= 0.8),
--- can be used in ftplugin/*.lua to manually enable treesitter highlights.
--- Compared against `vim.treesitter.start()`, it adds some more "safe-guards";
--- This works only if treesitter parser has been already installed *through* nvim-treesitter
--- because the neovim core's built-in parser queries may not be compatible (see M.has_parser)
function M.setup_highlight(lang, bufnr)
  if bufnr == 0 or bufnr == nil then
    bufnr = vim.api.nvim_get_current_buf()
  end

  if M.has_parser(lang, bufnr) then  -- excludes built-in parser
    vim.treesitter.start(bufnr, lang)
    return true
  else
    return false
  end
end

---------------------------------------------------------------------------
-- Treesitter Parsers (automatic installation and repair)
---------------------------------------------------------------------------

  -- Note: parsers are installed at $VIMPLUG/nvim-treesitter/parser/
M.parsers_to_install = vim.tbl_flatten {
  false and { -- regular (not applied; using minimal)
    "bash", "bibtex", "c", "cmake", "cpp", "css", "cuda", "dockerfile", "fish", "glimmer", "go", "graphql",
    "html", "http", "java", "javascript", "json", "json5", "jsonc", "latex", "lua",
    "make", "markdown", "markdown_inline", "perl", "python",
    "regex", "rst", "ruby", "rust", "scss", "toml", "tsx", "typescript", "vim", "yaml",
  },
  { -- minimal
    "bash", "json", "latex", "lua", "make", "markdown", "python", "query", "vim", "yaml",
    vim.fn.has('nvim-0.9.0') > 0 and "vimdoc" or nil,
  },
}

---More robust version of has_parser, returning false even when the parser
---may throw an error when it's outdated or incompatible with the current runtime.
---It actually concerns treesitter parsers installed through nvim-treesitter ONLY,
---ignoring neovim core's built-in parsers at $VIMRUNTIME which may cause
---lots of many errors when loaded and used with incompatible queries.
---See also "Conflicting parser paths": https://github.com/nvim-treesitter/nvim-treesitter/issues/3970
---@return boolean
function M.has_parser(lang, bufnr)
  -- first make sure nvim-treesitter is eagerly loaded so &rtp always contains $VIMPLUG/nvim-treesitter
  pcall(require, "nvim-treesitter")

  -- `all=false` assumes $VIMPLUG/nvim-treesitter precedes $VIMRUNTIME in &runtimepath.
  local parsers_so = vim.tbl_filter(function(path)
    return vim.startswith(path, os.getenv("VIMPLUG") or '???')  -- ignore built-in parsers
  end, vim.api.nvim_get_runtime_file(('parser/%s.so'):format(lang), false))
  if #parsers_so == 0 then
    return false
  end

  -- Protect get_parser call because nvim-treesitter can still throw errors
  -- when parsers are outdated
  local ok, parser = pcall(function()
    return require("nvim-treesitter.parsers").get_parser(bufnr or 0, lang)
  end)
  return ok and parser ~= nil
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
    require("nvim-treesitter.install").ensure_installed(langs)
  end
end

local function try_recover_parser_errors(lang, err)
  -- This is a fatal, unrecoverable error where treesitter parsers must be re-installed.
  if err and err:match('invalid node type') then
  else
    return false  -- Do not handle any other general errors (e.g. parser does not exist)
  end

  vim.api.nvim_echo({{ err, 'Error' }}, true, {})
  vim.cmd [[
    " workaround: disable TextChangedI autocmds that may cause treesitter errors
    silent! autocmd! cmp_nvim_ultisnips
    silent! autocmd! TreesitterUpdateParsing
  ]]

  -- Try to recover automatically, if nvim-treesitter is still importable.
  local noti_opts = { print = true, timeout = 10000, title = 'config/treesitter' }
  vim.notify("Fatal error on treesitter parsers (see :messages). " ..
             "Trying to reinstall treesitter parsers...",
             vim.log.levels.WARN, noti_opts)

  -- Force-reinstall all treesitter parsers.
  vim.schedule(function()
    vim.defer_fn(function()
      require('nvim-treesitter.install').commands.TSInstallSync["run!"](lang);
      require('nvim-treesitter.install').commands.TSUpdateSync.run();
      vim.notify("Treesitter parsers have been re-installed. Please RESTART neovim.",
                 vim.log.levels.INFO, noti_opts)
    end, 1000)
  end)

  return true
end

-- Incompatibility between vim.treesitter core API and outdated nvim-treesitter
-- may cause startup errors. Try to inform users with more informative message.
vim.schedule(function()
  if not pcall(require, 'nvim-treesitter') then
    vim.notify("nvim-treesitter is outdated. Please update the plugin (:Lazy update).",
      vim.log.levels.ERROR, { title = 'config/treesitter.lua' })
  end
end)


-- Make sure TS syntax tree is updated when needed by plugin (with some throttling)
-- even if the `highlight` module is not enabled.
-- See https://github.com/nvim-treesitter/nvim-treesitter/issues/2492
function M.TreesitterParse(bufnr)
  bufnr = bufnr or 0
  if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

  if not vim.bo[bufnr].filetype or vim.bo[bufnr].buftype ~= "" then
    return false  -- only works for a normal file-type buffer
  end

  local ts_parsers = require("nvim-treesitter.parsers")
  local lang = ts_parsers.ft_to_lang(vim.bo[bufnr].filetype)

  local ok, parser = pcall(function()
    return ts_parsers.get_parser(bufnr, lang)
  end)
  if not ok then
    try_recover_parser_errors(lang, parser)
    parser = nil
  end

  -- Update the treesitter parse tree for the current buffer.
  if parser then
    return parser:parse()
  else
    return false
  end
end

---------------------------------------------------------------------------
-- Custom treesitter queries
---------------------------------------------------------------------------

-- Language-specific Overrides of query files (see GH-1441, GH-1513) {{{
local function readfile(path)
  local f = io.open(path, 'r')
  assert(f, "IO Failed : " .. path)
  local content = f:read('*a')
  f:close()
  return content
end
function M.load_custom_query(lang, query_name)
  -- See ~/.config/nvim/queries/
  local return_all_matches = false
  local query_path = string.format("queries/%s/%s.scm", lang, query_name)
  local query_file = vim.api.nvim_get_runtime_file(query_path, return_all_matches)[1]

  if not M.has_parser(lang) then
    local msg = string.format("Warning: treesitter parser %s not found. Restart vim or run :TSUpdate?", lang)
    vim.notify(msg, vim.log.levels.WARN, { title = "nvim/lua/config/treesitter.lua" })
    return nil
  end
  local text = readfile(query_file)
  vim.treesitter.query.set(lang, query_name, text)
  return text
end

function M.setup_custom_queries()
  -- python(fold): make import regions foldable.
  M.load_custom_query("python", "folds")  -- $DOTVIM/queries/python/folds.scm
end


---------------------------------------------------------------------------
-- Utilities
---------------------------------------------------------------------------

function M.setup_keymap()
  -- treesitter-playground is deprecated in favor of vim.treesitter.* APIs.
  if vim.fn.has('nvim-0.10') > 0 then
    vim.fn.CommandAlias("TSPlaygroundToggle", "InspectTree", true)
    vim.keymap.set('n', '<leader>tsh', '<cmd>Inspect<CR>')

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
