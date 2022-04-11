-- Treesitter config
-- https://github.com/nvim-treesitter/nvim-treesitter

if not pcall(require, 'nvim-treesitter') then
  return
end

local ts_configs = require("nvim-treesitter.configs")
local ts_parsers = require("nvim-treesitter.parsers")

ts_configs.setup {
 -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = {
    "bash", "bibtex", "c", "cmake", "cpp", "css", "cuda", "dockerfile", "fish", "glimmer", "go", "graphql",
    "html", "http", "java", "javascript", "json", "json5", "jsonc", "latex", "lua", "make", "perl",
    "python", "regex", "rst", "ruby", "rust", "scss", "toml", "tsx", "typescript", "vim", "yaml"
  },

  -- List of parsers to ignore installing
  ignore_install = {
    "phpdoc",      -- Not compatible with M1 mac
  },

  highlight = {
    -- TreeSitter's highlight/syntax support is yet experimental and has some issues.
    -- It overrides legacy filetype-based vim syntax, and colorscheme needs to be treesitter-aware.
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

-- Make sure TS syntax tree is updated when needed by plugin (with some throttling)
-- even if the `highlight` module is not enabled.
-- See https://github.com/nvim-treesitter/nvim-treesitter/issues/2492
_G.TreesitterParse = function()
  local lang = ts_parsers.ft_to_lang(vim.bo.filetype)
  local parser = ts_parsers.get_parser(vim.fn.bufnr(), lang)
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
    augroup END
  ]]
end


-- Folding support
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'


-- Playground keymappings
vim.cmd [[
nnoremap <leader>tsh     :TSHighlightCapturesUnderCursor<CR>

augroup TSPlaygroundConfig
  autocmd!
  autocmd FileType tsplayground  setlocal ts=2 sts=2 sw=2
augroup END
]]


-- nvim-gps
-- https://github.com/SmiteshP/nvim-gps#%EF%B8%8F-configuration
if pcall(require, 'nvim-gps') then
  require("nvim-gps").setup {
    -- Use the same separator as lualine.nvim
    separator = '  ',
  }
end
