-------------
-- LSP config
-------------
-- See 'plugins.ide' for the Plug specs

local M = {}

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

  -- Activate nvim-navic
  if client.server_capabilities.documentSymbolProvider then
    require('nvim-navic').attach(client, bufnr)
  end

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

end

-- Add global keymappings for LSP actions
function M._setup_lsp_keymap()
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


-- List LSP servers that will be automatically installed upon entering filetype for the first time.
-- LSP servers will be installed locally via mason at: ~/.local/share/nvim/mason/packages/
-- (lspconfig_name => { filetypes } or true)
local auto_lsp_servers = {
  -- @see $VIMPLUG/mason-lspconfig.nvim/lua/mason-lspconfig/mappings/filetype.lua
  ['pyright'] = true,
  ['ruff_lsp'] = false,  -- experimental
  ['vimls'] = true,
  ['lua_ls'] = true,
  ['bashls'] = true,
  ['tsserver'] = true,
  ['cssls'] = true,
  ['clangd'] = true,
  ['rust_analyzer'] = true,
  ['texlab'] = true,
  ['yamlls'] = true,
  ['taplo'] = true,  -- toml
  ['jsonls'] = true,
  ['lemminx'] = true,  -- xml
}

-- Refresh or force-update mason-registry if needed (e.g. pkgs are missing)
-- and execute the callback asynchronously.
local function maybe_refresh_mason_registry_and_then(callback, opts)
  local mason_registry = require("mason-registry")
  local function _notify(msg, opts)
    return vim.notify_once(msg, vim.log.levels.INFO,
      vim.tbl_deep_extend("force", { title = "config/lsp.lua" }, (opts or {})))
  end
  local h = nil
  if vim.tbl_count(mason_registry.get_all_packages()) == 0 then
    h = _notify("Initializing mason.nvim registry for the first time,\n" ..
               "please wait a bit until LSP servers start installed.")
    mason_registry.update(function()
      _notify("Updating mason.nvim registry done.")
      vim.schedule(callback)  -- must detach
    end)
  elseif (opts or {}).force then
    _notify("Updating mason.nvim registry ...")
    mason_registry.update(function()
      _notify("Updating mason.nvim registry done.")
      vim.schedule(callback)  -- must detach
    end)
  else
    callback()  -- don't refresh, for fast startup
  end
end

function M._setup_mason()
  -- Mason: LSP Auto installer
  -- https://github.com/williamboman/mason.nvim#default-configuration
  require("mason").setup()
  require("mason-lspconfig").setup()

  -- ensure_installed: Install auto_lsp_servers on demand (FileType)
  maybe_refresh_mason_registry_and_then(M._ensure_mason_installed)
end

-- Install auto_lsp_servers on demand (FileType)
M._ensure_mason_installed = function()
  local augroup = vim.api.nvim_create_augroup('mason_autoinstall', { clear = true })
  local lspconfig_to_package = require("mason-lspconfig.mappings.server").lspconfig_to_package
  local filetype_mappings = require("mason-lspconfig.mappings.filetype")
  local _requested = {}

  local ft_handler = {}
  for ft, lsp_names in pairs(filetype_mappings) do
    lsp_names = vim.tbl_filter(function(lsp_name)
      return auto_lsp_servers[lsp_name] == true or vim.tbl_contains(auto_lsp_servers[lsp_name] or {}, lsp_name)
    end, lsp_names)

    ft_handler[ft] = vim.schedule_wrap(function()
      for _, lsp_name in pairs(lsp_names) do
        local pkg_name = lspconfig_to_package[lsp_name]
        local ok, pkg = pcall(require("mason-registry").get_package, pkg_name)
        if ok and not pkg:is_installed() and not _requested[pkg_name] then
          _requested[pkg_name] = true
          require("mason-lspconfig.install").install(pkg)  -- async
        end
      end
    end)

    -- Create FileType handler to auto-install LSPs for the &filetype
    if vim.tbl_count(lsp_names) > 0 then
      vim.api.nvim_create_autocmd('FileType', {
        pattern = ft,
        group = augroup,
        desc = string.format('Auto-install LSP server: %s (for %s)', table.concat(lsp_names, ","), ft),
        callback = function() ft_handler[ft]() end,
        once = true,
      })
    end
  end

  -- Since this works asynchronously, apply on the already opened buffer as well
  vim.tbl_map(function(buf)
    local valid = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'buflisted')
    if not valid then return end
    local handler = ft_handler[vim.bo[buf].filetype]
    if handler then handler() end
  end, vim.api.nvim_list_bufs())
end

-- Optional and additional LSP setup options other than (common) on_attach, capabilities, etc.
-- @see(config): https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local lsp_setup_opts = {}
M.lsp_setup_opts = lsp_setup_opts

-- (lsp_name: string) => function(client, init_result), see :help vim.lsp.start_client()
local on_init = {}
M.on_init = {}

lsp_setup_opts['pyright'] = {
  settings = {
    -- https://github.com/microsoft/pyright/blob/main/docs/settings.md
    python = {
      analysis = {
        typeCheckingMode = "basic",
      }
    },
  },
}

lsp_setup_opts['ruff_lsp'] = {
  init_options = {
    -- https://github.com/charliermarsh/ruff-lsp#settings
    settings = {
      fixAll = true,
      organizeImports = false,  -- let isort take care of organizeImports
      -- extra CLI arguments
      -- https://beta.ruff.rs/docs/configuration/#command-line-interface
      -- https://beta.ruff.rs/docs/rules/
      args = { "--ignore", table.concat({
        "E402", -- module-import-not-at-top-of-file
        "E501", -- line-too-long
        "E731", -- lambda-assignment
      }, ',') },
    },
  }
}
on_init['ruff_lsp'] = function(client, _)
  -- Disable hover in favor of Pyright
  if client.server_capabilities then
    client.server_capabilities.hoverProvider = false
  end
end

lsp_setup_opts['lua_ls'] = {
  settings = {
    Lua = {
      -- See https://github.com/LuaLS/lua-language-server/blob/master/doc/en-us/config.md
      runtime = {
        version = 'LuaJIT',   -- Lua 5.1/LuaJIT
      },
      diagnostics = {
        -- Ignore some false-positive diagnostics for neovim lua config
        disable = { 'redundant-parameter', 'duplicate-set-field', },
      },
      completion = { callSnippet = "Disable" },
      workspace = {
        maxPreload = 8000,

        -- Do not prompt "Do you need to configure your work environment as ..."
        checkThirdParty = false,

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
on_init['lua_ls'] = function(client, _)
  -- Note that server_capabilities config shouldn't be done in on_attach
  -- due to delayed execution (see neovim/nvim-lspconfig#2542)
  if client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.semanticTokensProvider = false  -- turn off semantic tokens
  end
end

lsp_setup_opts['bashls'] = {
  filetypes = { 'sh', 'zsh' },
}

lsp_setup_opts['yamlls'] = {
  settings = {
    -- https://github.com/redhat-developer/yaml-language-server#language-server-settings
    yaml = {
      keyOrdering = false,
    },
  }
}

-- Call lspconfig[...].setup for all installed LSP servers with common opts
local function setup_lsp(lsp_name)
  local cmp_nvim_lsp = require('cmp_nvim_lsp')
  local default_opts = {
    on_init = on_init[lsp_name],
    on_attach = on_attach,

    capabilities = (function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- nvim-cmp completion support
      capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)
      -- Make sure to use utf-8 offset. clangd defaults to utf-16 (see null-ls.vim#428)
      capabilities.offsetEncoding = 'utf-8'
      return capabilities
    end)(),
  }

  -- Configure lua_ls to support neovim Lua runtime APIs
  if lsp_name == 'lua_ls' then
    require("neodev").setup { }
  end

  -- Customize the options passed to the server
  local opts = vim.tbl_extend("force", default_opts, M.lsp_setup_opts[lsp_name] or {})
  require('lspconfig')[lsp_name].setup(opts)
end

-- lsp configs are lazy-loaded or can be triggered after LSP installation,
-- so we need a way to make LSP clients attached to already existing buffers.
local attach_lsp_to_existing_buffers = vim.schedule_wrap(function()
  -- this can be easily achieved by firing an autocmd event for the open buffers.
  -- See lspconfig.configs (config.autostart)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local valid = vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, 'buflisted')
    if valid and vim.bo[bufnr].buftype == "" then
      local augroup_lspconfig = vim.api.nvim_create_augroup('lspconfig', { clear = false })
      vim.api.nvim_exec_autocmds("FileType", { group = augroup_lspconfig, buffer = bufnr })
    end
  end
end)

--- setup all known and available LSP servers that are installed
function M._setup_lspconfig()
  local all_known_lsps = require('mason-lspconfig.mappings.server').lspconfig_to_package
  local lsp_uninstalled = {}   --- { lspconfig name => mason package name }
  local mason_need_refresh = false

  for lsp_name, package_name in pairs(all_known_lsps) do
    if require('mason-registry').is_installed(package_name) then
      -- Perform lspconfig[lsp_name].setup {}
      setup_lsp(lsp_name)
    else
      if not require('mason-registry').has_package(package_name) then
        mason_need_refresh = true
      end
      lsp_uninstalled[lsp_name] = package_name
    end
  end

  maybe_refresh_mason_registry_and_then(function()
    -- mason.nvim does not launch lsp when installed for the first time
    -- we attach a manual callback to setup LSP and launch
    for lsp_name, package_name in pairs(lsp_uninstalled) do
      local ok, pkg = pcall(require('mason-registry').get_package, package_name)
      if ok then
        pkg:on("install:success", vim.schedule_wrap(function()
          setup_lsp(lsp_name)
          attach_lsp_to_existing_buffers()  -- TODO: reload only the buffers that matches filetype.
        end))
      end
    end

    -- Make sure LSP clients are attached to already existing buffers prior to this config.
    attach_lsp_to_existing_buffers()
  end, { force = mason_need_refresh })

  -- Add backward-compatible lsp installation related commands
  vim.cmd [[
    command! LspInstallInfo   Mason
  ]]
end

-------------------------
-- LSP Handlers (general)
-------------------------
function M._setup_lsp_handlers()
  -- :help lsp-method
  -- :help lsp-handler
  -- :help lsp-handler-configuration
  --  https://github.com/neovim/nvim-lspconfig/wiki/UI-Customization
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
function M._setup_diagnostic()
  local icons = {
    [vim.diagnostic.severity.ERROR] = "✘",
    [vim.diagnostic.severity.WARN] = "",
    [vim.diagnostic.severity.INFO] = "i",
    [vim.diagnostic.severity.HINT] = "󰌶",
  }

  -- Customize how to show diagnostics:
  -- @see https://github.com/neovim/nvim-lspconfig/wiki/UI-customization
  -- @see https://github.com/neovim/neovim/pull/16057 for new APIs
  -- @see :help vim.diagnostic.config()
  vim.diagnostic.config {
    -- No virtual text (distracting!), show popup window on hover.
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
      prefix = vim.fn.has('nvim-0.10') > 0 and function(diagnostic)  ---@param diagnostic Diagnostic
        return (icons[diagnostic.severity] or "") .. " "
      end,
    },
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
    return vim.diagnostic.open_float({ bufnr = 0, scope = "cursor" })
  end

  -- Show diagnostics in a pop-up window on hover
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

  -- Redefine signs (:help diagnostic-signs) and highlights (:help diagnostic-highlights)
  do
    vim.fn.sign_define("DiagnosticSignError",  {text = icons[vim.diagnostic.severity.ERROR], texthl = "DiagnosticSignError"})
    vim.fn.sign_define("DiagnosticSignWarn",   {text = icons[vim.diagnostic.severity.WARN],  texthl = "DiagnosticSignWarn"})
    vim.fn.sign_define("DiagnosticSignInfo",   {text = icons[vim.diagnostic.severity.INFO],  texthl = "DiagnosticSignInfo"})
    vim.fn.sign_define("DiagnosticSignHint",   {text = icons[vim.diagnostic.severity.HINT],  texthl = "DiagnosticSignHint"})
  end
  require('utils.rc_utils').RegisterHighlights(function()
    vim.cmd [[
      hi DiagnosticSignError    guifg=#e6645f ctermfg=167
      hi DiagnosticSignWarn     guifg=#b1b14d ctermfg=143
      hi DiagnosticSignHint     guifg=#3e6e9e ctermfg=75

      hi DiagnosticVirtualTextError   guifg=#a6242f  gui=italic,underdashed,underline
      hi DiagnosticVirtualTextWarn    guifg=#777744  gui=italic,underdashed,underline
      hi DiagnosticVirtualTextHint    guifg=#555555  gui=italic,underdashed,underline
    ]]
  end)

  -- Turning on and off diagnostics
  -- Disable default commands, assuming the plugin is always lazy-loaded
  vim.g.toggle_lsp_diagnostics_loaded_install = 1
  require('toggle_lsp_diagnostics').init(vim.diagnostic.config())

  do
    vim.cmd [[
      command! DiagnosticsDisableBuffer       :lua vim.diagnostic.disable(0)
      command! DiagnosticsEnableBuffer        :lua vim.diagnostic.enable(0)
      command! DiagnosticsDisableAll          :lua vim.diagnostic.disable()
      command! DiagnosticsEnableAll           :lua vim.diagnostic.enable()
      command! DiagnosticsVirtualTextToggle   :lua require('toggle_lsp_diagnostics').toggle_diagnostic('virtual_text')
      command! DiagnosticsUnderlineToggle     :lua require('toggle_lsp_diagnostics').toggle_diagnostic('underline')
    ]]
  end
end

---------------------------------
-- nvim-cmp: completion support
---------------------------------
-- https://github.com/hrsh7th/nvim-cmp#recommended-configuration
-- ~/.vim/plugged/nvim-cmp/lua/cmp/config/default.lua

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, 'buftype') == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

local truncate = function(text, max_width)
  if #text > max_width then
    return string.sub(text, 1, max_width) .. "…"
  else
    return text
  end
end


local cmp_helper = {}

M.setup_cmp = function()
  local cmp = require('cmp')
  local SelectBehavior = require('cmp.types.cmp').SelectBehavior
  local ContextReason = require('cmp.types.cmp').ContextReason

  vim.o.completeopt = "menu,menuone,noselect"

  -- cmp.setup { ... }
  -- See ~/.vim/plugged/nvim-cmp/lua/cmp/config/default.lua
  local snippet = {
    expand = function(args)
      vim.fn["UltiSnips#Anon"](args.body)
    end,
  }
  local window = {
    documentation = {
      border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
    },
    completion = {
      -- Use border for the completion window.
      border = { '┌', '─', '┐', '│', '┘', '─', '└', '│' },

      -- Due to the border, move left the completion window by 1 column
      -- so that text in the editor and on completion item can be aligned.
      col_offset = -1,

      winhighlight = 'Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None',
    }
  }
  local mapping = {
    -- See ~/.vim/plugged/nvim-cmp/lua/cmp/config/mapping.lua
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete({ reason = ContextReason.Manual }),
    ['<C-y>'] = cmp.config.disable,
    ['<C-e>'] = cmp.mapping.close(),
    ['<Down>'] = cmp.mapping.select_next_item({ behavior = SelectBehavior.Select }),
    ['<Up>'] = cmp.mapping.select_prev_item({ behavior = SelectBehavior.Select }),
    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = SelectBehavior.Insert }),
    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = SelectBehavior.Insert }),
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
  }
  local formatting = {
    format = function(entry, vim_item)
      -- Truncate the item if it is too long
      vim_item.abbr = truncate(vim_item.abbr, 80)
      -- fancy icons and a name of kind
      pcall(function()  -- protect the call against potential API breakage (lspkind GH-45).
        local lspkind = require("lspkind")
        vim_item.kind_symbol = (lspkind.symbolic or lspkind.get_symbol)(vim_item.kind)
        vim_item.kind = " " .. vim_item.kind_symbol .. " " .. vim_item.kind
      end)

      -- The 'menu' section: source, detail information (lsp, snippet), etc.
      -- set a name for each source (see the sources section below)
      vim_item.menu = ({
        buffer        = "Buffer",
        nvim_lsp      = "LSP",
        ultisnips     = "",
        nvim_lua      = "Lua",
        latex_symbols = "Latex",
      })[entry.source.name] or string.format("%s", entry.source.name)

      -- highlight groups for item.menu
      vim_item.menu_hl_group = ({
        buffer = "CmpItemMenuBuffer",
        nvim_lsp = "CmpItemMenuLSP",
        path = "CmpItemMenuPath",
        ultisnips = "CmpItemMenuSnippet",
      })[entry.source.name]  -- default is CmpItemMenu

      -- detail information (optional)
      local cmp_item = entry:get_completion_item()  --- @type lsp.CompletionItem

      if entry.source.name == 'nvim_lsp' then
        -- Display which LSP servers this item came from.
        local lspserver_name = nil
        pcall(function()
          lspserver_name = entry.source.source.client.name
          vim_item.menu = lspserver_name
        end)

        -- Some language servers provide details, e.g. type information.
        -- The details info hide the name of lsp server, but mostly we'll have one LSP
        -- per filetype, and we use special highlights so it's OK to hide it..
        local detail_txt = (function(cmp_item)
          if not cmp_item.detail then return nil end

          if lspserver_name == "pyright" and cmp_item.detail == "Auto-import" then
            local label = (cmp_item.labelDetails or {}).description
            return label and (" " .. truncate(label, 20)) or nil
          else
            return truncate(cmp_item.detail, 50)
          end
        end)(cmp_item)
        if detail_txt then
          vim_item.menu = detail_txt
          vim_item.menu_hl_group = 'CmpItemMenuDetail'
        end

      elseif entry.source.name == 'zsh' then
        -- cmp-zsh: Display documentation for cmdline flag ('' denotes zsh)
        ---@diagnostic disable-next-line: undefined-field
        local detail = cmp_item.documentation
        if detail then
          vim_item.menu = detail
          vim_item.menu_hl_group = 'CmpItemMenuZsh'
          vim_item.kind = '  ' .. 'zsh'
        end

      elseif entry.source.name == 'ultisnips' then
        ---@diagnostic disable-next-line: undefined-field
        local description = (cmp_item.snippet or {}).description
        if description then
          vim_item.menu = truncate(description, 40)
        end
      end

      -- Add a little bit more padding
      vim_item.menu = " " .. vim_item.menu
      return vim_item
    end
  }
  local sources = {
    -- Note: make sure you have proper plugins specified in plugins.vim
    -- https://github.com/topics/nvim-cmp
    { name = 'nvim_lsp', priority = 100 },
    { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
    { name = 'path', priority = 30, },
    { name = 'buffer', priority = 10 },
  }
  local sorting = {
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
  }

  cmp.setup {
    snippet = snippet,
    window = window,
    mapping = mapping,
    formatting = formatting,
    sources = sources,
    sorting = sorting,
  }

  -- filetype-specific sources
  require("cmp_zsh").setup { filetypes = { "bash", "zsh" } }
  cmp.setup.filetype({'sh', 'zsh', 'bash'}, {
    sources = cmp.config.sources({
      { name = 'zsh', priorty = 100 },
      { name = 'nvim_lsp', priority = 50 },
      { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
      { name = 'path', priority = 30, },
      { name = 'buffer', priority = 10 },
    }),
  })

  -- Highlights
  require('utils.rc_utils').RegisterHighlights(cmp_helper.apply_highlight)
end

-- Custom sorting/ranking for completion items.
cmp_helper.compare = {
  -- Deprioritize items starting with underscores (private or protected)
  --- @param lhs cmp.Entry
  --- @param rhs cmp.Entry
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

-- Highlights with bordered completion window (GH-224, GH-472)
function cmp_helper.apply_highlight()
  vim.cmd [[
    " Dark background, and white-ish foreground
    highlight! CmpPmenu         guibg=#242a30
    highlight! CmpPmenuBorder   guibg=#242a30
    highlight! CmpItemAbbr      guifg=#eeeeee
    highlight! CmpItemMenuDefault   guifg=white
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

-- Commands and Keymaps for PeekDefinition
function M._define_peek_definition()
  vim.cmd [[
    command! -nargs=0 PeekDefinition      :lua _G.PeekDefinition()
    command! -nargs=0 PreviewDefinition   :PeekDefinition
    " Preview definition.
    nmap <leader>K     <cmd>PeekDefinition<CR>
    nmap <silent> gp   <cmd>lua _G.PeekDefinition()<CR>
    " Preview type definition.
    nmap <silent> gT   <cmd>lua _G.PeekDefinition('textDocument/typeDefinition')<CR>
  ]]

  -- workaround a bug where quickpreview winhighlight (background) is not cleaned up
  -- for the buffer that was opened in the preview window for the first time.
  vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = '*',
    group = vim.api.nvim_create_augroup('PeekDefinition_quickui_workaround', { clear = true }),
    callback = function()
      local is_floating = vim.api.nvim_win_get_config(0).relative ~= ""
      if is_floating then return end
      for key, value in pairs(vim.opt_local.winhighlight:get()) do
        if value == "QuickPreview" then
          vim.opt_local.winhighlight:remove(key)
        end
      end
    end,
  })
end


------------
-- LSPstatus
------------
function M.setup_lsp_status()
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

  -- :LspStatus (command): display lsp status
  vim.cmd [[
  command! -nargs=0 LspStatus   echom v:lua.LspStatus()
  ]]
end

-- LspStatus(): status string for airline
_G.LspStatus = function()
  if #vim.lsp.get_active_clients({bufnr = 0}) > 0 then
    return require('lsp-status').status()
  end
  return ''
end

-- Other LSP commands
-- :LspDebug, :CodeActions
function M._setup_lsp_commands()
  vim.cmd [[
    command! -nargs=0 LspDebug  :tab drop $HOME/.cache/nvim/lsp.log

    command! -nargs=0 CodeActions   :lua vim.lsp.buf.code_action()
    call CommandAlias("CA", "CodeActions")
  ]]
end

-----------------------------------
--- navic (LSP context)
-----------------------------------
function M.setup_navic()
  require('nvim-navic').setup {
    -- Use the same separator as lualine.nvim
    separator = '  ',
  }
end

-----------------------------------
--- Fidget.nvim (LSP status widget)
-----------------------------------
function M.setup_fidget()
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
function M.setup_trouble()
  require("trouble").setup {
    -- https://github.com/folke/trouble.nvim#setup
    mode = "document_diagnostics",
    auto_preview = false,
  }
end

----------------------------------------
-- Formatting, Linting, and Code actions
----------------------------------------
function M.setup_null_ls()
  local null_ls = require("null-ls")
  local h = require("null-ls.helpers")

  -- Monkey-patching because of a performance bug on startup (jose-elias-alvarez/null-ls.nvim#1564)
  require('null-ls.client').retry_add = require('null-ls.client').try_add

  -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/CONFIG.md
  -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

  local function condition_has_executable(cmd)
    return function() return vim.fn.executable(cmd) > 0 end
  end
  local _exclude_nil = function(tbl)
    return vim.tbl_filter(function(s) return s ~= nil end, tbl)
  end

  -- null-ls sources (mason.nvim installation is recommended)
  -- @see $VIMPLUG/null-ls.nvim/doc/BUILTINS.md
  -- @see $VIMPLUG/null-ls.nvim/lua/null-ls/builtins/
  local sources = {}
  do -- [[ formatting ]]
    vim.list_extend(sources, {
      -- python
      require('null-ls.builtins.formatting.yapf').with {
        condition = condition_has_executable('yapf'),
      },
      require('null-ls.builtins.formatting.isort').with {
        condition = condition_has_executable('isort'),
      },
      -- javascript, css, html, etc.
      require('null-ls.builtins.formatting.prettier').with {
        condition = condition_has_executable('prettier'),
      },
    })
  end
  do -- [[ diagnostics (linting) ]]
    -- python: pylint, flake8
    vim.list_extend(sources, {
      require('null-ls.builtins.diagnostics.pylint').with {
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          condition = function(utils)  ---@param utils ConditionalUtils
            -- https://pylint.pycqa.org/en/latest/user_guide/run.html#command-line-options
            return condition_has_executable('pylint') and (
              utils.root_has_file("pylintrc") or
              utils.root_has_file(".pylintrc") or
              utils.root_has_file("setup.cfg") or
              utils.root_has_file("pyproject.toml")
            )
          end,
      },
      require('null-ls.builtins.diagnostics.flake8').with {
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          -- Activate when flake8 is available and any project config is found,
          -- per https://flake8.pycqa.org/en/latest/user/configuration.html
          condition = function(utils)  ---@param utils ConditionalUtils
            return condition_has_executable('flake8') and (
              utils.root_has_file("setup.cfg") or
              utils.root_has_file("tox.ini") or
              utils.root_has_file(".flake8") or
              utils.root_has_file("pyproject.toml")
            )
          end,
          -- Ignore some too aggressive errors (indentation, lambda, etc.)
          -- @see https://pycodestyle.pycqa.org/en/latest/intro.html#error-codes
          extra_args = {"--extend-ignore", "E111,E114,E402,E731"},
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
      },
    })
    -- rust: rustfmt
    vim.list_extend(sources, {
      require('null-ls.builtins.formatting.rustfmt').with {
        condition = condition_has_executable('rustfmt'),
        extra_args = { "--edition=2018" },
      },
    })
  end

  null_ls.setup({
    sources = _exclude_nil(sources),

    on_attach = on_attach,
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
end


-- Entrypoint
function M.setup_lsp()
  M._setup_mason()
  M._setup_lspconfig()
  M._setup_diagnostic()
  M._setup_lsp_keymap()
  M._setup_lsp_commands()
  M._setup_lsp_handlers()
  M._define_peek_definition()
end

-- Entrypoint: setup all
function M.setup_all()
  M.setup_lsp()
  M.setup_cmp()
  M.setup_lsp_status()
  M.setup_navic()
  M.setup_fidget()
  M.setup_trouble()
  M.setup_null_ls()
end


-- Resourcing support
if RC and RC.should_resource() then
  M.setup_all()
end

(RC or {}).lsp = M
return M
