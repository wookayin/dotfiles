-- Treesitter config
-- https://github.com/nvim-treesitter/nvim-treesitter

local ts_configs = require("nvim-treesitter.configs")
local ts_parsers = require("nvim-treesitter.parsers")

-- Compatibility layer for neovim < 0.9.0 (see neovim#22761)
if not vim.treesitter.query.set then
  vim.treesitter.query.set = require("vim.treesitter.query").set_query
end

-- Note: parsers are installed at ~/.vim/plugged/nvim-treesitter/parser/
local parsers_to_install = {
  default = {
    "bash", "bibtex", "c", "cmake", "cpp", "css", "cuda", "dockerfile", "fish", "glimmer", "go", "graphql",
    "html", "http", "java", "javascript", "json", "json5", "jsonc", "latex", "lua", "make", "perl",
    "python", "regex", "rst", "ruby", "rust", "scss", "toml", "tsx", "typescript", "vim", "yaml",
  },
  minimal = {
    "bash", "json", "latex", "lua", "make", "python", "vim", "yaml"
  },
}
parsers_to_install = parsers_to_install.minimal
if vim.fn.has('nvim-0.9.0') > 0 then
  table.insert(parsers_to_install, "vimdoc")
end

if vim.fn.has('mac') > 0 then
  -- Disable 'dockerfile' until nvim-treesitter/nvim-treesitter#3515 is resolved
  parsers_to_install = vim.tbl_filter(function(x) return x ~= "dockerfile" end, parsers_to_install)
  pcall(function() require 'nvim-treesitter.install'.uninstall('dockerfile') end)
end

-- @see https://github.com/nvim-treesitter/nvim-treesitter#modules
ts_configs.setup {
  ensure_installed = parsers_to_install,

  highlight = {
    -- TreeSitter's highlight/syntax support is yet experimental and has some issues.
    -- It overrides legacy filetype-based vim syntax, and colorscheme needs to be treesitter-aware.
    -- Note: for some ftplugins (e.g. for lua and vim), treesitter highlight might be manually started
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

-- Make sure TS syntax tree is updated when needed by plugin (with some throttling)
-- even if the `highlight` module is not enabled.
-- See https://github.com/nvim-treesitter/nvim-treesitter/issues/2492
function _G.TreesitterParse(bufnr)
  bufnr = bufnr or 0
  if bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end

  if not vim.bo[bufnr].filetype or vim.bo[bufnr].buftype ~= "" then
    return false  -- only works for a normal file-type buffer
  end

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
local function throttle(fn, ms)
  local timer = vim.loop.new_timer()
  local running = false
  return function(...)
    if not running then
      timer:start(ms, 0, function() running = false end)
      running = true
      pcall(vim.schedule_wrap(fn), select(1, ...))
    end
  end
end
if not (ts_configs.get_module('highlight') or {}).enable then
  _G.TreesitterParseDebounce = throttle(_G.TreesitterParse, 100)  -- 100 ms
  vim.cmd [[
    augroup TreesitterUpdateParsing
      autocmd!
      autocmd TextChanged,TextChangedI *   call v:lua.TreesitterParseDebounce()
      autocmd BufReadPost *                lua _G.TreesitterParse()
    augroup END
  ]]

  -- Apply TreesitterParse() at least once for the existing buffers.
  require('utils.rc_utils').bufdo(_G.TreesitterParse)
end


-- Folding support
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'


-- Language-specific Overrides of query files (see GH-1441, GH-1513) {{{

local function readfile(path)
  local f = io.open(path, 'r')
  local content = f:read('*a')
  f:close()
  return content
end
function _G.TreesitterLoadCustomQuery(lang, query_name)
  -- See ~/.config/nvim/queries/
  local return_all_matches = false
  local query_path = string.format("queries/%s/%s.scm", lang, query_name)
  local query_file = vim.api.nvim_get_runtime_file(query_path, return_all_matches)[1]

  if not ts_parsers.has_parser(lang) then
    local msg = string.format("Warning: treesitter parser %s not found. Restart vim or run :TSUpdate?", lang)
    vim.notify(msg, 'WARN', { title = "nvim/lua/config/treesitter.lua" })
    return
  end
  vim.treesitter.query.set(lang, query_name, readfile(query_file))
end

-- python(fold): until GH-1451 is merged
_G.TreesitterLoadCustomQuery("python", "folds")

-- }}}


-- Playground keymappings
vim.cmd [[
nnoremap <leader>tsh     :TSHighlightCapturesUnderCursor<CR>

augroup TSPlaygroundConfig
  autocmd!
  autocmd FileType tsplayground  setlocal ts=2 sts=2 sw=2
augroup END
]];
