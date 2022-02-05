-- Treesitter config
-- https://github.com/nvim-treesitter/nvim-treesitter

-- lazy-load the plugin.
vim.fn['plug#load']('nvim-treesitter', 'treesitter-playground')

require'nvim-treesitter.configs'.setup {
 -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = "maintained",

  -- List of parsers to ignore installing
  ignore_install = { },

  highlight = {
    -- TODO: There are many annoying issues in treesitter;
    -- e.g., conflict with existing filetype-based vim syntax.
    -- We disable highlight until it becomes mature enough
    enable = false,

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
  }
}

-- Folding support
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'nvim_treesitter#foldexpr()'


-- Playground keymappings
vim.cmd [[
nnoremap <leader>tsh     :TSHighlightCapturesUnderCursor<CR>
]]
