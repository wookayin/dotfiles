-------------
-- LSP config
-------------
-- See ~/.dotfiles/vim/plugins.vim for Plug directives

local lspconfig = require('lspconfig')

-- lsp_signature
-- https://github.com/ray-x/lsp_signature.nvim#full-configuration
local on_attach_lsp_signature = function(client, bufnr)
  require "lsp_signature".on_attach({
      bind = true, -- This is mandatory, otherwise border config won't get registered.
      floating_window = true,
      handler_opts = {
        border = "single"
      },
      zindex = 99,     -- <100 so that it does not hide completion popup.
      fix_pos = false, -- Let signature window change its position when needed, see GH-53
    })
end

-- Customize LSP behavior
-- [[ A callback executed when LSP engine attaches to a buffer. ]]
local on_attach = function(client, bufnr)
  -- Always use signcolumn for the current buffer
  vim.wo.signcolumn = 'yes:1'

  -- Activate LSP signature.
  on_attach_lsp_signature(client, buffer)

  -- Keybindings
  -- https://github.com/neovim/nvim-lspconfig#keybindings-and-completion
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local opts = { noremap=true, silent=true }
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  if vim.fn.exists(':Telescope') then
    buf_set_keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts)
  else
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  end
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  --buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  --buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  --buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  --buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  --buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  --buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  --buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  --buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
end


-- Register and activate LSP servers (managed by nvim-lsp-installer)
-- @see(config):     https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
local builtin_lsp_servers = {
  -- List name of LSP servers that will be automatically installed and managed by :LspInstall.
  -- LSP servers will be installed locally at: ~/.local/share/nvim/lsp_servers
  -- @see(lspinstall): https://github.com/williamboman/nvim-lsp-installer
  'pyright',
  'vimls',
  'tsserver',
}

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = on_attach
  }

  -- (optional) Customize the options passed to the server
  -- if server.name == "tsserver" then
  --     opts.root_dir = function() ... end
  -- end

  -- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
  server:setup(opts)
  vim.cmd [[ do User LspAttachBuffers ]]
end)

-- Automatically install if a required LSP server is missing.
for _, lsp_name in ipairs(builtin_lsp_servers) do
  local ok, lsp = require('nvim-lsp-installer.servers').get_server(lsp_name)
  if ok and not lsp:is_installed() then
    vim.defer_fn(function()
      -- lsp:install()   -- headless
      lsp_installer.install(lsp_name)   -- with UI (so that users can be notified)
    end, 0)
  end
end


--- Customize how to show diagnostics: Do not use distracting virtual text
-- :help lsp-handler-configuration
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = false,     -- disable virtual text
      signs = true,             -- show signs
      update_in_insert = false, -- delay update diagnostics
      -- display_diagnostic_autocmds = { "InsertLeave" },
    }
  )

-- Instead, show line diagnostics in a pop-up window on hover
vim.cmd [[
augroup LSPDiagnosticsOnHover
  autocmd!
  autocmd CursorHold * lua vim.lsp.diagnostic.show_line_diagnostics({focusable = false})
augroup END
]]


---------------------------------
-- nvim-compe: completion support
---------------------------------
-- https://github.com/hrsh7th/nvim-compe#lua-config

-- TODO: Previously there was `longest` too. Maybe needed for coc.nvim?
vim.o.completeopt = "menuone,noselect"

local compe = require('compe')
compe.setup {
    enabled = true;
    autocomplete = true;
    debug = false;
    min_length = 1;
    preselect = 'disable';
    throttle_time = 80;
    source_timeout = 200;
    resolve_timeout = 500;
    incomplete_delay = 400;
    allow_prefix_unmatch = false;
    max_abbr_width = 1000;
    max_kind_width = 1000;
    max_menu_width = 1000000;
    documentation = true;

    source = {
        path = true;
        buffer = true;
        calc = true;
        nvim_lsp = true;
        nvim_lua = true;
        spell = true;
        tags = true;
        snippets_nvim = true;
        treesitter = true;
        -- ultisnips = true;    -- TODO: conflicts with LSP completion
        -- luasnip = true;
    };
}

-- Keymaps for comp
vim.cmd [[ inoremap <silent><expr> <C-Space> compe#complete() ]]
vim.cmd [[ inoremap <silent><expr> <C-Space> compe#complete() ]]
vim.cmd [[ inoremap <silent><expr> <CR>      compe#confirm('<CR>') ]]
vim.cmd [[ inoremap <silent><expr> <C-e>     compe#close('<C-e>') ]]
vim.cmd [[ inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 }) ]]
vim.cmd [[ inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 }) ]]

-- https://github.com/hrsh7th/nvim-compe#how-to-use-tab-to-navigate-completion-menu
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') ~= nil
end

-- Use Shift-tab/tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  --elseif vim.fn['vsnip#available'](1) == 1 then
  --  return t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  --elseif vim.fn['vsnip#jumpable'](-1) == 1 then
  --  return t "<Plug>(vsnip-jump-prev)"
  else
    -- If <S-Tab> is not working in your terminal, change it to <C-h>
    return t "<S-Tab>"
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})

-- Workaround a compe.nim bug where completion doesn't get closed when '(' is typed
-- https://github.com/hrsh7th/nvim-compe/issues/436
_G.compe_parenthesis_fix = function()
  if vim.fn.pumvisible() then
    vim.cmd [[ call timer_start(0, { -> luaeval('require"compe"._close()') }) ]]
  end
  return t "("
end
vim.api.nvim_set_keymap("i", "(", "v:lua.compe_parenthesis_fix()", {expr = true})


------------
-- LSPstatus
------------
local lsp_status = require('lsp-status')
lsp_status.config({
    -- Avoid using use emoji-like or full-width characters
    -- because it can often break rendering within tmux and some terminals
    -- See ~/.vim/plugged/lsp-status.nvim/lua/lsp-status.lua
    indicator_hint = '!',
    status_symbol = ' ',
})
lsp_status.register_progress()

-- LspStatus(): status string for airline
_G.LspStatus = function()
  if #vim.lsp.buf_get_clients() > 0 then
    return lsp_status.status()
  end
  return ''
end

-- :LspStatus (command): display lsp status
vim.cmd [[
command! -nargs=0 LspStatus   echom v:lua.LspStatus()
]]


---------------
-- trouble.nvim
---------------
require("trouble").setup {
    -- https://github.com/folke/trouble.nvim#setup
    mode = "lsp_document_diagnostics",
    auto_preview = false,
}


---------------
-- Telescope
---------------
local telescope = require('telescope')

-- Custom Telescope mappings
vim.cmd [[
command! -nargs=0 Highlights    :Telescope highlights
]]

-- Telescope extensions
if vim.fn['HasPlug']('telescope-frecency.nvim') == 1 then
  telescope.load_extension("frecency")
  vim.cmd [[
    command! -nargs=0 Frecency      :Telescope frecency
  ]]
end
