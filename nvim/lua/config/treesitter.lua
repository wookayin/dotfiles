-- Treesitter config
-- https://github.com/nvim-treesitter/nvim-treesitter

require'nvim-treesitter.configs'.setup {
 -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = "maintained",

  -- List of parsers to ignore installing
  ignore_install = {
    "phpdoc",      -- Not compatible with M1 mac
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

-- Folding support
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'


-- Playground keymappings
vim.cmd [[
nnoremap <leader>tsh     :TSHighlightCapturesUnderCursor<CR>
]]
