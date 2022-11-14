-------------
-- LSP config
-------------
-- See ~/.dotfiles/vim/plugins.vim for the Plug directives

if not pcall(require, 'lspconfig') then
  print("Warning: lspconfig not available, skipping configuration.")
  return
end
local lspconfig = require('lspconfig')

-- lsp_signature
local on_attach_lsp_signature = function(client, bufnr)
  -- https://github.com/ray-x/lsp_signature.nvim#full-configuration-with-default-values
  require('lsp_signature').on_attach({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    floating_window = true,
    handler_opts = {
      border = "single"
    },
    zindex = 99, -- <100 so that it does not hide completion popup.
    fix_pos = false, -- Let signature window change its position when needed, see GH-53
    toggle_key = '<M-x>', -- Press <Alt-x> to toggle signature on and off.
  })
end

-- Customize LSP behavior via on_attach
local on_attach = function(client, bufnr)
  -- [[ A callback executed when LSP engine attaches to a buffer. ]]

  -- Always use signcolumn for the current buffer
  if vim.bo.filetype == 'python' then
    vim.wo.signcolumn = 'yes:2'
  else
    vim.wo.signcolumn = 'yes:1'
  end

  -- Activate LSP signature on attach.
  on_attach_lsp_signature(client, bufnr)

  -- Activate LSP status on attach (see a configuration below).
  require('lsp-status').on_attach(client)

  -- Keybindings
  -- https://github.com/neovim/nvim-lspconfig#keybindings-and-completion
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local opts = { noremap = true, silent = true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  if vim.fn.exists(':Telescope') then
    buf_set_keymap('n', 'gr', '<cmd>Telescope lsp_references<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts)
    buf_set_keymap('n', 'gt', '<cmd>Telescope lsp_type_definitions<CR>', opts)
  else
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  end
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  --buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '[e', '<cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<CR>', opts)
  buf_set_keymap('n', ']e', '<cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<CR>', opts)
  --buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  --buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  --buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  --buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  --buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)

  -- Commands
  vim.api.nvim_buf_create_user_command(bufnr, "LspRename", function(opt)
    vim.lsp.buf.rename(opt.args ~= "" and opt.args or nil)
  end, { nargs = '?', desc = "Rename the current symbol at the cursor." })

  -- Disable specific LSP capabilities: see nvim-lspconfig#1891
  if client.name == "sumneko_lua" and client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
  end
end

-- Add global keymappings for LSP actions
do
  vim.cmd [[
    " F3, F12: goto definition
    map  <F12>  gd
    imap <F12>  <ESC>gd
    map  <F3>   <F12>
    imap <F3>   <F12>

    " Shift+F12: show usages/references
    map  <S-F12>  gr
    imap <S-F12>  <ESC>gr
  ]]
end


-- Register and activate LSP servers (managed by nvim-lsp-installer)
local builtin_lsp_servers = {
  -- List name of LSP servers that will be automatically installed and managed by :LspInstall.
  -- LSP servers will be installed locally at: ~/.local/share/nvim/lsp_servers
  -- @see(lspinstall): https://github.com/williamboman/nvim-lsp-installer
  'pyright',
  'vimls',
  'tsserver',
  'sumneko_lua',
}

-- Optional and additional LSP setup options other than (common) on_attach, capabilities, etc.
-- @see(config): https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
_G.lsp_setup_opts = {}

_G.lsp_setup_opts['pyright'] = {
  settings = {
    -- https://github.com/microsoft/pyright/blob/main/docs/settings.md
    python = {
      analysis = {
        typeCheckingMode = "basic",
      }
    },
  },
}

_G.lsp_setup_opts['sumneko_lua'] = {
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',   -- Lua 5.1/LuaJIT
      },
      completion = { callSnippet = "Disable" },
      workspace = {
        maxPreload = 8000,
        -- Add additional paths for lua packages
        library = (function()
          local library = {}
          if vim.fn.has('mac') > 0 then
            -- http://www.hammerspoon.org/Spoons/EmmyLua.html
            -- Add a line `hs.loadSpoon('EmmyLua')` on the top in ~/.hammerspoon/init.lua
            library[string.format('%s/.hammerspoon/Spoons/EmmyLua.spoon/annotations', os.getenv 'HOME')] = true
          end
          return library
        end)(),
      },
    },
  },
}

-- Configure sumneko_lua to support neovim Lua runtime APIs
require("neodev").setup { }

local lsp_installer = require("nvim-lsp-installer")
lsp_installer.on_server_ready(function(server)
  local cmp_nvim_lsp = require('cmp_nvim_lsp')
  local opts = {
    on_attach = on_attach,

    -- Suggested configuration by nvim-cmp
    capabilities = (cmp_nvim_lsp.default_capabilities or cmp_nvim_lsp.update_capabilities)(
      vim.lsp.protocol.make_client_capabilities()
    ),
  }

  -- Customize the options passed to the server
  opts = vim.tbl_extend("error", opts, _G.lsp_setup_opts[server.name] or {})

  -- This setup() function is exactly the same as lspconfig's setup function (:help lspconfig-quickstart)
  server:setup(opts)
  vim.cmd [[ do User LspAttachBuffers ]]
end)

-- Automatically install if a required LSP server is missing.
for _, lsp_name in ipairs(builtin_lsp_servers) do
  local ok, lsp = require('nvim-lsp-installer.servers').get_server(lsp_name)
  ---@diagnostic disable-next-line: undefined-field
  if ok and not lsp:is_installed() then
    vim.defer_fn(function()
      -- lsp:install()   -- headless
      lsp_installer.install(lsp_name)   -- with UI (so that users can be notified)
    end, 0)
  end
end

-------------------------
-- LSP Handlers (general)
-------------------------
do
  -- :help lsp-method
  -- :help lsp-handler
  -- :help lsp-handler-configuration
  local lsp_handlers_hover = vim.lsp.with(vim.lsp.handlers.hover, {
    border = 'single'
  })
  vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
    local bufnr, winnr = lsp_handlers_hover(err, result, ctx, config)
    if winnr ~= nil then
      -- opacity/alpha for hover window
      vim.api.nvim_win_set_option(winnr, "winblend", 20)
    end
    return bufnr, winnr
  end
end


------------------
-- LSP diagnostics
------------------
if vim.diagnostic then
  -- Customize how to show diagnostics:
  -- @see https://github.com/neovim/nvim-lspconfig/wiki/UI-customization
  -- @see https://github.com/neovim/neovim/pull/16057 for new APIs
  vim.diagnostic.config {
    -- No virtual text (distracting!), show popup window on hover.
    virtual_text = false,
    underline = {
      -- Do not underline text when severity is low (INFO or HINT).
      severity = { min = vim.diagnostic.severity.WARN },
    },
    float = {
      source = 'always',
      focusable = true,
      focus = false,
      border = 'single',

      -- Customize how diagnostic message will be shown: show error code.
      format = function(diagnostic)
        -- See null-ls.nvim#632, neovim#17222 for how to pick up `code`
        local user_data
        user_data = diagnostic.user_data or {}
        user_data = user_data.lsp or user_data.null_ls or user_data
        local code = (
            -- TODO: symbol is specific to pylint (will be removed)
            diagnostic.symbol or diagnostic.code or
                user_data.symbol or user_data.code
            )
        if code then
          return string.format("%s (%s)", diagnostic.message, code)
        else return diagnostic.message
        end
      end,
    }
  }
  _G.LspDiagnosticsShowPopup = function()
    return vim.diagnostic.open_float(0, { scope = "cursor" })
  end
end

-- Show diagnostics in a pop-up window on hover
do
  _G.LspDiagnosticsPopupHandler = function()
    local current_cursor = vim.api.nvim_win_get_cursor(0)
    local last_popup_cursor = vim.w.lsp_diagnostics_last_cursor or { nil, nil }

    -- Show the popup diagnostics window,
    -- but only once for the current cursor location (unless moved afterwards).
    if not (current_cursor[1] == last_popup_cursor[1] and current_cursor[2] == last_popup_cursor[2]) then
      vim.w.lsp_diagnostics_last_cursor = current_cursor
      local _, winnr = _G.LspDiagnosticsShowPopup()
      if winnr ~= nil then
        -- opacity/alpha for diagnostics
        vim.api.nvim_win_set_option(winnr, "winblend", 20)
      end
    end
  end
  vim.cmd [[
  augroup LSPDiagnosticsOnHover
    autocmd!
    autocmd CursorHold *   lua _G.LspDiagnosticsPopupHandler()
  augroup END
  ]]
end

-- Redefine signs (:help diagnostic-signs)
do
  vim.fn.sign_define("DiagnosticSignError",  {text = "✘", texthl = "DiagnosticSignError"})
  vim.fn.sign_define("DiagnosticSignWarn",   {text = "", texthl = "DiagnosticSignWarn"})
  vim.fn.sign_define("DiagnosticSignInfo",   {text = "i", texthl = "DiagnosticSignInfo"})
  vim.fn.sign_define("DiagnosticSignHint",   {text = "", texthl = "DiagnosticSignHint"})
  vim.cmd [[
    hi DiagnosticSignError    guifg=#e6645f ctermfg=167
    hi DiagnosticSignWarn     guifg=#b1b14d ctermfg=143
    hi DiagnosticSignHint     guifg=#3e6e9e ctermfg=75
  ]]
end

-- Commands for temporarily turning on and off diagnostics (for the current buffer or globally)
do
  vim.cmd [[
    command! DiagnosticsDisable     :lua vim.diagnostic.disable(0)
    command! DiagnosticsEnable      :lua vim.diagnostic.enable(0)
    command! DiagnosticsDisableAll  :lua vim.diagnostic.disable()
    command! DiagnosticsEnableAll   :lua vim.diagnostic.enable()
  ]]
end

---------------------------------
-- nvim-cmp: completion support
---------------------------------
-- https://github.com/hrsh7th/nvim-cmp#recommended-configuration
-- ~/.vim/plugged/nvim-cmp/lua/cmp/config/default.lua

vim.o.completeopt = "menu,menuone,noselect"

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

local cmp = require('cmp')
local cmp_helper = {}
local cmp_types = require('cmp.types.cmp')
local cmp_theme = cmp.config.window and 'dark' or 'light'

-- See ~/.vim/plugged/nvim-cmp/lua/cmp/config/default.lua
cmp.setup {
  snippet = {
    expand = function(args)
      vim.fn["UltiSnips#Anon"](args.body)
    end,
  },
  window = {
    documentation = {
      border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
    },
    completion = {
      border = (cmp_theme == 'dark' and { '┌', '─', '┐', '│', '┘', '─', '└', '│' } or nil),
      winhighlight = 'Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None',
    },
  },
  mapping = {
    -- See ~/.vim/plugged/nvim-cmp/lua/cmp/config/mapping.lua
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-y>'] = cmp.config.disable,
    ['<C-e>'] = cmp.mapping.close(),
    ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp_types.SelectBehavior.Select }),
    ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp_types.SelectBehavior.Select }),
    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp_types.SelectBehavior.Insert }),
    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp_types.SelectBehavior.Insert }),
    ['<CR>'] = cmp.mapping.confirm({ select = false }),
    ['<Tab>'] = { -- see GH-880, GH-897
      i = function(fallback) -- see GH-231, GH-286
        if cmp.visible() then cmp.select_next_item()
        elseif has_words_before() then cmp.complete()
        else fallback() end
      end,
    },
    ['<S-Tab>'] = {
      i = function(fallback)
        if cmp.visible() then cmp.select_prev_item()
        else fallback() end
      end,
    },
  },
  formatting = {
    format = function(entry, vim_item)
      -- Truncate the item if it is too long
      local max_width = 80
      if #vim_item.abbr > max_width then
        vim_item.abbr = string.sub(vim_item.abbr, 1, max_width) .. "…"
      end
      -- fancy icons and a name of kind
      pcall(function()  -- protect the call against potential API breakage (lspkind GH-45).
        vim_item.kind = " " .. require("lspkind").get_symbol(vim_item.kind) .. " " .. vim_item.kind
      end)
      -- set a name for each source (see the sources section below)
      vim_item.menu = ({
        buffer        = "[Buffer]",
        nvim_lsp      = "[LSP]",
        luasnip       = "[LuaSnip]",
        ultisnips     = "[UltiSnips]",
        nvim_lua      = "[Lua]",
        latex_symbols = "[Latex]",
      })[entry.source.name] or string.format("[%s]", entry.source.name)

      if vim_item.menu == "[LSP]" then
        -- Display which LSP servers this item came from.
        pcall(function()
          vim_item.menu = " " .. entry.source.source.client.name
        end)
      end

      return vim_item
    end,
  },
  sources = {
    -- Note: make sure you have proper plugins specified in plugins.vim
    -- https://github.com/topics/nvim-cmp
    { name = 'nvim_lsp', priority = 100 },
    { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
    { name = 'path', priority = 30, },
    { name = 'buffer', priority = 10 },
  },
  sorting = {
    -- see ~/.vim/plugged/nvim-cmp/lua/cmp/config/compare.lua
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      function(...) return cmp_helper.compare.prioritize_argument(...) end,
      function(...) return cmp_helper.compare.deprioritize_underscore(...) end,
      cmp.config.compare.recently_used,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
}

-- Custom sorting/ranking for completion items.
cmp_helper.compare = {
  -- Deprioritize items starting with underscores (private or protected)
  deprioritize_underscore = function(lhs, rhs)
    local l = (lhs.completion_item.label:find "^_+") and 1 or 0
    local r = (rhs.completion_item.label:find "^_+") and 1 or 0
    if l ~= r then return l < r end
  end,
  -- Prioritize items that ends with "= ..." (usually for argument completion).
  prioritize_argument = function(lhs, rhs)
    local l = (lhs.completion_item.label:find "=$") and 1 or 0
    local r = (rhs.completion_item.label:find "=$") and 1 or 0
    if l ~= r then return l > r end
  end,
}


-- Highlights for nvim-cmp's custom popup menu (GH-224)
do
  vim.cmd [[
    " Light theme: Compatible with Pmenu (#fff3bf)
    hi! link CmpPmenu         Pmenu
    hi! link CmpPmenuBorder   Pmenu

    hi! CmpItemAbbr           guifg=#111111
    hi! CmpItemAbbrMatch      guifg=#f03e3e gui=bold
    hi! CmpItemAbbrMatchFuzzy guifg=#fd7e14 gui=bold
    hi! CmpItemAbbrDeprecated guifg=#adb5bd
    hi! CmpItemKindDefault    guifg=#cc5de8
    hi! link CmpItemKind      CmpItemKindDefault
    hi! CmpItemMenu           guifg=#cfa050
  ]]
end

-- Highlights with bordered completion window (GH-472)
if cmp_theme == 'dark' then
  vim.cmd [[
    " Dark background, and white-ish foreground
    highlight! CmpPmenu         guibg=#242a30
    highlight! CmpPmenuBorder   guibg=#242a30
    highlight! CmpItemAbbr      guifg=#eeeeee
    " gray
    highlight! CmpItemAbbrDeprecated    guibg=NONE gui=strikethrough guifg=#808080
    " fuzzy matching
    highlight! CmpItemAbbrMatch         guibg=NONE guifg=#f03e3e gui=bold
    highlight! CmpItemAbbrMatchFuzzy    guibg=NONE guifg=#fd7e14 gui=bold

    " Item Kinds. defaults to CmpItemKind (#cc5de8)
    " see ~/.vim/plugged/nvim-cmp/lua/cmp/types/lsp.lua
    " {✅Class, ✅Module, ✅Interface, Struct, ✅Function, ✅Method, ✅Constructor,
    "  ✅Variable, ✅Property, Field, ✅Unit, Value, Enum, EnumMember, Event,
    "  ✅Keyword, Color, File, Reference, Folder, Constant, Operator, TypeParameter,
    "  ✅Snippet, ✅Text}

    " see SemshiGlobal
    highlight!      CmpItemKindModule        guibg=NONE guifg=#FF7F50
    highlight!      CmpItemKindClass         guibg=NONE guifg=#FFAF00
    highlight! link CmpItemKindStruct        CmpItemKindClass
    highlight!      CmpItemKindVariable      guibg=NONE guifg=#9CDCFE
    highlight!      CmpItemKindProperty      guibg=NONE guifg=#9CDCFE
    highlight!      CmpItemKindFunction      guibg=NONE guifg=#C586C0
    highlight! link CmpItemKindConstructor   CmpItemKindFunction
    highlight! link CmpItemKindMethod        CmpItemKindFunction
    highlight!      CmpItemKindKeyword       guibg=NONE guifg=#FF5FFF
    highlight!      CmpItemKindText          guibg=NONE guifg=#D4D4D4
    highlight!      CmpItemKindUnit          guibg=NONE guifg=#D4D4D4
    highlight!      CmpItemKindConstant      guibg=NONE guifg=#409F31
    highlight!      CmpItemKindSnippet       guibg=NONE guifg=#E3E300
  ]]
end

-----------------------------
-- Configs for PeekDefinition
-----------------------------
_G.PeekDefinition = function(lsp_request_method)
  local params = vim.lsp.util.make_position_params()
  local definition_callback = function(_, result, ctx, config)
    -- This handler previews the jump location instead of actually jumping to it
    -- see $VIMRUNTIME/lua/vim/lsp/handlers.lua, function location_handler
    if result == nil or vim.tbl_isempty(result) then
      print("PeekDefinition: " .. "cannot find the definition.")
      return nil
    end
    --- either Location | LocationLink
    --- https://microsoft.github.io/language-server-protocol/specification#location
    local def_result = result[1]

    -- Peek defintion. Currently, use quickui but a better alternative should be found.
    -- vim.lsp.util.preview_location(result[1])
    local def_uri = def_result.uri or def_result.targetUri
    local def_range = def_result.range or def_result.targetSelectionRange
    vim.fn['quickui#preview#open'](vim.uri_to_fname(def_uri), {
      cursor = def_range.start.line + 1,
      number = 1, -- show line number
      persist = 0,
    })
  end
  -- Asynchronous request doesn't work very smoothly, so we use synchronous one with timeout;
  -- return vim.lsp.buf_request(0, 'textDocument/definition', params, definition_callback)
  lsp_request_method = lsp_request_method or 'textDocument/definition'
  local results, err = vim.lsp.buf_request_sync(0, lsp_request_method, params, 1000)
  if results then
    for client_id, result in pairs(results) do
      definition_callback(client_id, result.result)
    end
  else
    print("PeekDefinition: " .. err)
  end
end

do  -- Commands and Keymaps for PeekDefinition
  vim.cmd [[
    command! -nargs=0 PeekDefinition      :lua _G.PeekDefinition()
    command! -nargs=0 PreviewDefinition   :PeekDefinition
    " Preview definition.
    nmap <leader>K     <cmd>PeekDefinition<CR>
    nmap <silent> gp   <cmd>lua _G.PeekDefinition()<CR>
    " Preview type definition.
    nmap <silent> gT   <cmd>lua _G.PeekDefinition('textDocument/typeDefinition')<CR>
  ]]
end


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

  -- If true, automatically sets b:lsp_current_function
  -- (no longer used in favor of treesitter + nvim-gps)
  current_function = false,
})
lsp_status.register_progress()

-- LspStatus(): status string for airline
do
  _G.LspStatus = function()
    if #vim.lsp.get_active_clients({bufnr = 0}) > 0 then
      return lsp_status.status()
    end
    return ''
  end

  -- :LspStatus (command): display lsp status
  vim.cmd [[
  command! -nargs=0 LspStatus   echom v:lua.LspStatus()
  ]]
end

-- Other LSP commands
-- :LspDebug, :CodeActions
local function define_lsp_commands()
  vim.cmd [[
    command! -nargs=0 LspDebug  :tab drop $HOME/.cache/nvim/lsp.log

    command! -nargs=0 CodeActions   :lua vim.lsp.buf.code_action()
    call CommandAlias("CA", "CodeActions")
  ]]
end
define_lsp_commands()


-----------------------------------
--- Fidget.nvim (LSP status widget)
-----------------------------------

if pcall(require, 'fidget') then
  -- https://github.com/j-hui/fidget.nvim/blob/main/doc/fidget.md
  -- Note: This will override lsp-status.nvim (progress handlers).
  require("fidget").setup {
    text = {
      --see ~/.vim/plugged/fidget.nvim/lua/fidget/spinners.lua
      spinner = "zip",
    },
    window = {
      relative = "win",
      blend = 50,
    },
  }
end


---------------
-- trouble.nvim
---------------
require("trouble").setup {
  -- https://github.com/folke/trouble.nvim#setup
  mode = "document_diagnostics",
  auto_preview = false,
}


----------------------------------------
-- Formatting, Linting, and Code actions
----------------------------------------
if pcall(require, "null-ls") then
  local null_ls = require("null-ls")
  local h = require("null-ls.helpers")

  -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/CONFIG.md
  -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
  -- @see ~/.vim/plugged/null-ls.nvim/lua/null-ls/builtins

  -- @see BUILTINS.md#conditional-registration
  local _cond = function(cmd, source)
    if vim.fn.executable(cmd) > 0 then return source
    else return nil end
  end
  local _exclude_nil = function(tbl)
    return vim.tbl_filter(function(s) return s ~= nil end, tbl)
  end

  null_ls.setup({
    sources = _exclude_nil {
      -- [[ Auto-Formatting ]]
      -- @python (pip install yapf isort)
      _cond("yapf", null_ls.builtins.formatting.yapf),
      _cond("isort", null_ls.builtins.formatting.isort),
      -- @javascript
      null_ls.builtins.formatting.prettier,

      -- Linting (diagnostics)
      -- @python: pylint, flake8
      _cond("pylint", null_ls.builtins.diagnostics.pylint.with({
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          condition = function(utils)
            -- https://pylint.pycqa.org/en/latest/user_guide/run.html#command-line-options
            return (
              utils.root_has_file("pylintrc") or
              utils.root_has_file(".pylintrc")) or
              utils.root_has_file("setup.cfg")
          end,
        })),
      _cond("flake8", null_ls.builtins.diagnostics.flake8.with({
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          -- Activate when flake8 is available and any project config is found,
          -- per https://flake8.pycqa.org/en/latest/user/configuration.html
          condition = function(utils)
            return (
              utils.root_has_file("setup.cfg") or
              utils.root_has_file("tox.ini") or
              utils.root_has_file(".flake8"))
          end,
          -- Ignore some too aggressive errors (indentation, lambda, etc.)
          -- @see https://pycodestyle.pycqa.org/en/latest/intro.html#error-codes
          extra_args = {"--extend-ignore", "E111,E114,E731"},
          -- Override flake8 diagnostics levels
          -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/issues/538
          on_output = h.diagnostics.from_pattern(
            [[:(%d+):(%d+): ((%u)%w+) (.*)]],
            { "row", "col", "code", "severity", "message" },
            {
              severities = {
                E = h.diagnostics.severities["warning"], -- Changed to warning!
                W = h.diagnostics.severities["warning"],
                F = h.diagnostics.severities["information"],
                D = h.diagnostics.severities["information"],
                R = h.diagnostics.severities["warning"],
                S = h.diagnostics.severities["warning"],
                I = h.diagnostics.severities["warning"],
                C = h.diagnostics.severities["warning"],
              },
            }),
        })),
      -- @rust
      _cond("rustfmt", null_ls.builtins.formatting.rustfmt.with {
        extra_args = { "--edition=2018" }
      }),
    },

    should_attach = function(bufnr)
      -- Excludes some files on which it doesn't not make a sense to use linting.
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match("^git://") then return false end
      if bufname:match("^fugitive://") then return false end
      if bufname:match("/lib/python%d%.%d+/") then return false end
      return true
    end,

    -- Debug mode: Use :NullLsLog for viewing log files (~/.cache/nvim/null-ls.log)
    debug = false,
  })

  if vim.lsp.buf.format == nil then
    -- For neovim < 0.8.0, use the legacy formatting_sync API as fallback
    vim.lsp.buf.format = function(opts)
      return vim.lsp.buf.formatting_sync(opts, opts.timeout_ms)
    end
  end

  -- Commands for LSP formatting. :Format
  -- FormattingOptions: @see https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#formattingOptions
  vim.cmd [[
    command! LspFormatSync        lua vim.lsp.buf.format({timeout_ms = 5000})
    command! -range=0 Format      LspFormat
  ]]

  -- Automatic formatting
  -- see ~/.vim/after/ftplugin/python.vim for filetype use
  vim.cmd [[
    augroup LspAutoFormatting
    augroup END
    command! -nargs=? LspAutoFormattingOn      lua _G.LspAutoFormattingStart(<q-args>)
    command!          LspAutoFormattingOff     lua _G.LspAutoFormattingStop()
  ]]
  _G.LspAutoFormattingStart = function(misc)
    vim.cmd [[
    augroup LspAutoFormatting
      autocmd!
      autocmd BufWritePre *    :lua _G.LspAutoFormattingTrigger()
    augroup END
    ]]
    local msg = "Lsp Auto-Formatting has been turned on."
    if misc and misc ~= '' then
      msg = msg .. string.format("\n(%s)", misc)
    end
    msg = msg .. "\n\n" .. "To disable auto-formatting, run :LspAutoFormattingOff"
    vim.notify(msg, 'info', { title = "nvim/lua/config/lsp.lua", timeout = 1000 })
  end
  _G.LspAutoFormattingTrigger = function()
    -- Disable on some files (e.g., site-packages or python built-ins)
    -- Note that `-` is a special character in Lua regex
    if vim.api.nvim_buf_get_name(0):match '/lib/python3.%d+/' then
      return false
    end
    -- TODO: Enable only on the current project specified by PATH.
    local formatting_clients = vim.tbl_filter(function(client)
      return client.server_capabilities.documentFormattingProvider
    end, vim.lsp.get_active_clients({bufnr = 0}))
    if vim.tbl_count(formatting_clients) > 0 then
      vim.lsp.buf.format({ timeout_ms = 2000 })
      return true
    end
    return false
  end
  _G.LspAutoFormattingStop = function()
    vim.cmd [[ autocmd! LspAutoFormatting ]]
    vim.notify("Lsp Auto-Formatting has been turned off.", 'warn')
  end

end -- if null-ls
