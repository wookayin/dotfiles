--------------
--- LSP config
--------------
-- See 'plugins.ide' for the Plug specs
-- nvim-cmp config has been moved to nvim/lua/config/completion.lua

local M = {}

-- lsp_signature
---@diagnostic disable-next-line: unused-local
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

--- A callback executed when LSP engine attaches to a buffer.
---@type fun(client: vim.lsp.Client, bufnr: integer)
local on_attach = function(client, bufnr)

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
  local bufmap = function(mode, lhs, rhs, opts)
    return vim.keymap.set(mode, lhs, rhs, vim.tbl_deep_extend("force", { remap = false, buffer = true }, opts or {}))
  end
  local nbufmap = function(lhs, rhs, opts) return bufmap('n', lhs, rhs, opts) end
  local function vim_cmd(x) return '<Cmd>' .. x .. '<CR>' end
  local function buf_command(...) vim.api.nvim_buf_create_user_command(bufnr, ...) end

  -- keymap for <count>gt (tabn) or gt (lsp)
  local gt_action = function(lsp_cmd)
    return function()
      local count = vim.v.count
      if count > 0 then vim.cmd(('tabn %d'):format(count))
      else vim.cmd(lsp_cmd)
      end
    end
  end

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  if pcall(require, 'fzf-lua') then
    nbufmap('gr', vim_cmd 'lua require("fzf-lua").lsp_references { jump_to_single_result = true, silent = true }', { nowait = true })
    nbufmap('gd', vim_cmd 'lua require("fzf-lua").lsp_definitions { jump_to_single_result = true, silent = true }')
    nbufmap('gi', vim_cmd 'lua require("fzf-lua").lsp_implementations { jump_to_single_result = true, silent = true }')
    nbufmap('gt', gt_action('lua require("fzf-lua").lsp_typedefs { jump_to_single_result = true, silent = true }'))
  else
    nbufmap('gd', vim_cmd 'lua vim.lsp.buf.definition()')
    nbufmap('gr', vim_cmd 'lua vim.lsp.buf.references()', { nowait = true })
    nbufmap('gi', vim_cmd 'lua vim.lsp.buf.implementation()')
    nbufmap('gt', gt_action('lua vim.lsp.buf.type_definition()'))
  end
  nbufmap('gD', vim_cmd 'lua vim.lsp.buf.declaration()')
  nbufmap('[d', vim_cmd 'lua vim.diagnostic.goto_prev()',
    { desc = 'goto previous diagnostic item' })
  nbufmap(']d', vim_cmd 'lua vim.diagnostic.goto_next()',
    { desc = 'goto next diagnostic item' })
  nbufmap('[e', vim_cmd 'lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })',
    { desc = 'goto previous error' })
  nbufmap(']e', vim_cmd 'lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })',
    { desc = 'goto next error' })
  --nbufmap('<space>wa', vim_cmd 'lua vim.lsp.buf.add_workspace_folder()')
  --nbufmap('<space>wr', vim_cmd 'lua vim.lsp.buf.remove_workspace_folder()')
  --nbufmap('<space>wl', vim_cmd 'lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))')
  nbufmap('<leader>rn', vim_cmd 'lua vim.lsp.buf.rename()')
  bufmap({'n', 'v'}, '<leader>ca', '<cmd>CodeActions<CR>')
  --nbufmap('<space>e', vim_cmd 'lua vim.lsp.diagnostic.show_line_diagnostics()')
  --nbufmap('<space>q', vim_cmd 'lua vim.lsp.diagnostic.set_loclist()')
  --nbufmap('<space>f', vim_cmd 'ua vim.lsp.buf.formatting()')

  -- Commands
  buf_command("LspRename", function(opt)
    vim.lsp.buf.rename(opt.args ~= "" and opt.args or nil)
  end, { nargs = '?', desc = "Rename the current symbol at the cursor." })

  buf_command("CodeActions", function(_)
    if pcall(require, "fzf-lua.previewer.codeaction") then
      if vim.fn.executable("delta") == 0 then
        vim.notify_once("delta (git-delta) not found. Please install delta to enable preview.", vim.log.levels.WARN)
      end
      require("fzf-lua").lsp_code_actions()  -- see config/fzf.lua
    else
      return vim.lsp.buf.code_action()
    end
  end, { nargs = 0, desc = "Code Actions (fzf-lua with preview)." })
  vim.fn.CommandAlias("CA", "CodeActions")

  -- inlay hints (experimental), need to turn it on manually
  if client.server_capabilities.inlayHintProvider and vim.fn.has('nvim-0.10') > 0 then
    local inlay = function(enable)
      if enable == 'toggle' then
        enable = not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
      end
      vim.lsp.inlay_hint.enable(enable, { bufnr = bufnr })
    end
    buf_command("InlayHintsToggle", function(_) inlay('toggle') end,
      { nargs = 0, desc = "Toggle inlay hints."})
    buf_command("ToggleInlayHints", "InlayHintsToggle", {})
    vim.fn.CommandAlias("ToggleInlayHints", "InlayHintsToggle")
    -- Toggling inlay hints: <leader>I or <Ctrl-Alt-Space>
    vim.keymap.set('n', '<leader>I', '<cmd>InlayHintsToggle<CR>', { buffer = true })
    vim.keymap.set('n', '<M-C-Space>', '<cmd>InlayHintsToggle<CR>', { buffer = true })
  end

end

--- Add global keymappings for LSP actions
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


--- @alias lspserver_name string
--- @alias vim_filetype string

--- List LSP servers that will be automatically installed upon entering filetype for the first time.
--- LSP servers will be installed locally via mason at: ~/.local/share/nvim/mason/packages/
--- @type table<lspserver_name, boolean|vim_filetype[]>
local auto_lsp_servers = {
  -- @see $VIMPLUG/mason-lspconfig.nvim/lua/mason-lspconfig/mappings/filetype.lua
  ['pyright'] = true,
  ['ruff_lsp'] = true,
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

--- Refresh or force-update mason-registry if needed (e.g. pkgs are missing)
--- and execute the callback asynchronously.
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
  ---@source $VIMPLUG/mason.nvim/lua/mason/settings.lua
  require("mason").setup {
    ui = {
      border = "rounded",
      keymaps = {
        toggle_help = "<F1>",
      }
    },
  }
  require("mason-lspconfig").setup()

  -- ensure_installed: Install auto_lsp_servers on demand (FileType)
  maybe_refresh_mason_registry_and_then(M._ensure_mason_installed)
end

--- Install auto_lsp_servers on demand (FileType)
function M._ensure_mason_installed()
  local augroup = vim.api.nvim_create_augroup('mason_autoinstall', { clear = true })
  local lspconfig_to_package = require("mason-lspconfig.mappings.server").lspconfig_to_package
  local filetype_mappings = require("mason-lspconfig.mappings.filetype")
  local _requested = {}

  local ft_handler = {}
  for ft, lsp_names in pairs(filetype_mappings) do
    lsp_names = vim.tbl_filter(function(lsp_name)
      ---@diagnostic disable-next-line: param-type-mismatch
      return auto_lsp_servers[lsp_name] == true or vim.tbl_contains(auto_lsp_servers[lsp_name] or {}, ft)
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
    local valid = vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
    if not valid then return end
    local handler = ft_handler[vim.bo[buf].filetype]
    if handler then handler() end
  end, vim.api.nvim_list_bufs())
end

--- Create the default capabilities to use for LSP server configuration.
---@return lsp.ClientCapabilities
function M.lsp_default_capabilities()
  -- Use default vim.lsp capabilities and apply some tweaks on capabilities.completion for nvim-cmp
  local capabilities = vim.tbl_deep_extend("force",
    vim.lsp.protocol.make_client_capabilities(),
    require('cmp_nvim_lsp').default_capabilities()
  )  --[[@as lsp.ClientCapabilities]]

  -- [Additional capabilities customization]
  -- Large workspace scanning may freeze the UI; see https://github.com/neovim/neovim/issues/23291
  if vim.fn.has('nvim-0.9') > 0 then
    capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false
  end
  return capabilities
end

-- Optional and additional LSP setup options other than (common) on_attach, capabilities, etc.
-- see(config): https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
-- see $VIMPLUG/nvim-lspconfig/lua/lspconfig/server_configurations/
---@type table<lspserver_name, false | table | fun():(table|false)>
local lsp_setup_opts = {}
M.lsp_setup_opts = lsp_setup_opts

---@see lsp.ClientConfig :help vim.lsp.start_client()
---@type table<lspserver_name, fun(client: vim.lsp.Client, init_result: table)>
local on_init = {}
M.on_init = on_init

---@param setup_name 'python'|'basedpyright' for pyright, use 'python'.
local pyright_opts = function(setup_name)
  return {
    -- https://github.com/microsoft/pyright/blob/main/docs/settings.md
    -- https://detachhead.github.io/basedpyright/
    settings = {
      [setup_name] = {
        analysis = {
          typeCheckingMode = "basic",
          -- see https://github.com/microsoft/pyright/blob/main/docs/import-resolution.md#resolution-order
          extraPaths = { "./python" },
        },
        -- Always use the current python in accordance with $PATH (the current conda/virtualenv).
        pythonPath = vim.fn.exepath("python3"),
      },
    },
  }
end

lsp_setup_opts['basedpyright'] = function()
  -- basedpyright: experimental drop-in replacement of pyright (that supports inlay hints!)
  -- To use it, simply install it with :Mason. When installed, basedpyright will be enabled
  -- in place of pyright; otherwise, fallback to the standard pyright.
  lsp_setup_opts['pyright'] = false
  return pyright_opts('basedpyright')
end

lsp_setup_opts['pyright'] = function()
  -- Do not setup pyright when basedpyright is installed.
  -- TODO: remove mason dependency.
  if require('mason-registry').is_installed('basedpyright') then
    return false
  end
  return pyright_opts('python')
end

lsp_setup_opts['ruff_lsp'] = function()
  local init_options = {
    -- https://github.com/astral-sh/ruff-lsp#settings
    -- https://github.com/astral-sh/ruff-lsp/blob/main/ruff_lsp/server.py
    -- Note: use pyproject.toml to configure ruff per project.
    settings = {
      fixAll = true,
      organizeImports = false,  -- let isort take care of organizeImports
      -- extra CLI arguments
      -- https://docs.astral.sh/ruff/configuration/#command-line-interface
      -- https://docs.astral.sh/ruff/rules/
      args = {
        "--preview", -- Use experimental features
        "--ignore", table.concat({
          "E111", -- indentation-with-invalid-multiple
          "E114", -- indentation-with-invalid-multiple-comment
          "E402", -- module-import-not-at-top-of-file
          "E501", -- line-too-long
          "E702", -- multiple-statements-on-one-line-semicolon
          "E731", -- lambda-assignment
          "F401", -- unused-import  (note: should be handled by pyright as 'hint')
        }, ','),
      },
    },
  };
  return { init_options = init_options }
end
on_init['ruff_lsp'] = function(client, _)
  if client.server_capabilities then
    -- Disable ruff hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
    -- Disable ruff formatting in favor of yapf (null-ls)
    -- NOTE: ruff-lsp's formatting is a bit buggy, doesn't respect indent_size
    client.server_capabilities.documentFormattingProvider = false
  end
end

lsp_setup_opts['lua_ls'] = function()
  local settings = {
    -- See https://github.com/LuaLS/lua-language-server/blob/master/doc/en-us/config.md
    -- See $MASON/packages/lua-language-server/libexec/locale/en-us/setting.lua
    -- See $MASON/packages/lua-language-server/libexec/script/config/template.lua
    Lua = {
      runtime = {
        version = 'LuaJIT',   -- Lua 5.1/LuaJIT
        pathStrict = true,    -- Do not unnecessarily recurse into subdirs of workspace directory
      },
      diagnostics = {
        -- Ignore some false-positive diagnostics for neovim lua config
        disable = { 'redundant-parameter', 'duplicate-set-field', },
      },
      hint = vim.fn.has('nvim-0.10') > 0 and {
        -- https://github.com/LuaLS/lua-language-server/wiki/Settings#hint
        enable = true, -- inlay hints
        paramType = true, -- Show type hints at the parameter of the function.
        paramName = "Literal", -- Show hints of parameter name (literal types only) at the function call.
        arrayIndex = "Auto", -- Show hints only when the table is greater than 3 items, or the table is a mixed table.
        setType = true,  -- Show a hint to display the type being applied at assignment operations.
      } or nil,
      completion = { callSnippet = "Disable" },
      workspace = {
        maxPreload = 8000,

        -- Do not prompt "Do you need to configure your work environment as ..."
        checkThirdParty = false,

        -- If running as a single file on root_dir = ./dotfiles,
        -- this will be in duplicate with library paths. Do not scan invalid lua libs
        ignoreDir = { '.*', 'vim/plugged', 'config/nvim', 'nvim/lua', },

        -- Add additional paths for lua packages
        library = (function()
          local library = {}
          if vim.fn.has('mac') > 0 then
            -- http://www.hammerspoon.org/Spoons/EmmyLua.html
            -- Add a line `hs.loadSpoon('EmmyLua')` on the top in ~/.hammerspoon/init.lua
            library[vim.fn.expand('$HOME/.hammerspoon/Spoons/EmmyLua.spoon/annotations')] = true
          end
          return library
        end)(),
      },
    },
  };
  return { settings = settings }
end
on_init['lua_ls'] = function(client, _)
  -- Note that server_capabilities config shouldn't be done in on_attach
  -- due to delayed execution (see neovim/nvim-lspconfig#2542)
  if client.server_capabilities then
    client.server_capabilities.documentFormattingProvider = false
  end
end

lsp_setup_opts['clangd'] = {
  -- Make sure to use utf-8 offset. clangd defaults to utf-16 (see jose-elias-alvarez/null-ls.nvim#429)
  -- against "multiple different client offset_encodings detected for buffer" error
  capabilities = {
    offsetEncoding = 'utf-8',
  }
}

lsp_setup_opts['bashls'] = {
  filetypes = { 'sh', 'zsh' },
}

lsp_setup_opts['ltex'] = {
  filetypes = { 'markdown', 'tex', 'gitcommit' },
  settings = {
    -- https://valentjn.github.io/ltex/settings.html
    ltex = {
    },
  },
}

lsp_setup_opts['yamlls'] = {
  settings = {
    -- https://github.com/redhat-developer/yaml-language-server#language-server-settings
    yaml = {
      keyOrdering = false,
    },
  }
}

--- Call lspconfig[...].setup for all installed LSP servers with common opts
local function setup_lsp(lsp_name)
  local common_opts = {
    on_init = on_init[lsp_name],
    on_attach = on_attach,
    capabilities = M.lsp_default_capabilities(),
  }

  -- Configure lua_ls to support neovim Lua runtime APIs
  if lsp_name == 'lua_ls' then
    local resolve_path = function(p) return assert(vim.loop.fs_realpath(vim.fs.normalize(p))) end
    local dotfiles_path = resolve_path('$HOME/.dotfiles')
    require("neodev").setup {
      -- Always add neovim plugins into lua_ls library, for any lua files (even if they are not nvim configs)
      -- see also: neodev.lsp.on_new_config(...), folke/neodev.nvim#158
      override = function(root_dir, library)
        root_dir = resolve_path(root_dir)
        if vim.startswith(root_dir, dotfiles_path) then
          library.enabled = true
          library.plugins = true
        end
      end,
    }
  end

  local opts = M.lsp_setup_opts[lsp_name]
  if opts == false then
    -- Explicitly configured to disable this LSP. Stop.
    return
  end

  opts = opts or {} -- 'nil' means using the default opts
  if type(opts) == 'function' then
    opts = opts()
  end

  if opts == false then
    -- Explicitly configured to disable this LSP (after evaluation). Stop.
    return
  end

  -- Merge with lang-specific options
  opts = vim.tbl_extend("force", {}, common_opts, opts)
  require('lspconfig')[lsp_name].setup(opts)
end

-- lsp configs are lazy-loaded or can be triggered after LSP installation,
-- so we need a way to make LSP clients attached to already existing buffers.
local attach_lsp_to_existing_buffers = vim.schedule_wrap(function()
  -- this can be easily achieved by firing an autocmd event for the open buffers.
  -- See lspconfig.configs (config.autostart)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local valid = vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
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

  -- Use a border for the floating :LspInfo window
  require("lspconfig.ui.windows").default_options.border = 'single'

  -- Add backward-compatible lsp installation related commands
  vim.cmd [[
    command! LspInstallInfo   Mason
  ]]
end


--------------------------
--- LSP Handlers (general)
--------------------------
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
      vim.wo[winnr].winblend = 10
    end
    return bufnr, winnr
  end
end


-------------------
--- LSP diagnostics
-------------------
function M._setup_diagnostic()
  local icons = {
    [vim.diagnostic.severity.ERROR] = "✘",
    [vim.diagnostic.severity.WARN] = "",
    [vim.diagnostic.severity.INFO] = "",
    [vim.diagnostic.severity.HINT] = "󰌶",
  }

  -- Customize how to show diagnostics:
  -- see https://github.com/neovim/nvim-lspconfig/wiki/UI-customization
  -- see https://github.com/neovim/neovim/pull/16057 for new APIs
  -- see :help vim.diagnostic.config()
  vim.diagnostic.config {
    -- Prioritize high severity more (for sign priority and virtual text order, etc.)
    -- diagnostic signs have a base priority of 10; Error = 13, Warn = 12, Info = 11, etc.
    severity_sort = true,

    signs = {
      text = icons,  -- neovim/neovim#26193 (0.10.0+)
    },

    -- No virtual text (distracting!), show popup window on hover.
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
      prefix = vim.fn.has('nvim-0.10') > 0 and
        function(diagnostic, i, total)  ---@param diagnostic vim.Diagnostic
          if total ~= nil and total > 4 and i > 4 then
            return i == 4 + 1 and string.format("⋯ (total %s):", total) or ""
          end
          return (icons[diagnostic.severity] or "") .. " "
        end or nil,
    },
    underline = {
      severity = { min = vim.diagnostic.severity.INFO },
    },
    float = {
      source = 'always',
      focusable = true,
      focus = false,
      border = 'single',

      -- Customize how diagnostic message will be shown: show error code.
      ---@param diagnostic vim.Diagnostic
      format = function(diagnostic)
        -- See null-ls.nvim#632, neovim#17222 for how to pick up `code`
        local user_data
        user_data = diagnostic.user_data or {}
        user_data = user_data.lsp or user_data.null_ls or user_data
        local code = (
            -- TODO: symbol is specific to pylint (will be removed)
            ---@diagnostic disable-next-line: undefined-field
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
        vim.wo[winnr].winblend = 20
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
  -- see vim.diagnostic.config, but we still keep legacy signs because other plugins (neotree, etc.) still use them
  do -- if vim.fn.has('nvim-0.10') == 0 then
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

------------------------------
--- Configs for PeekDefinition
------------------------------
_G.PeekDefinition = function(lsp_request_method)
  local params = vim.lsp.util.make_position_params()
  local definition_callback = function(_, result, ctx, config)
    -- This handler previews the jump location instead of actually jumping to it
    -- see $VIMRUNTIME/lua/vim/lsp/handlers.lua, function location_handler
    if result == nil or vim.tbl_isempty(result) then
      print("PeekDefinition: " .. "cannot find the definition.")
      return nil
    end

    --- result is of type either Location | LocationLink (or a list of such)
    --- https://microsoft.github.io/language-server-protocol/specification#location
    ---@type lsp.Location | lsp.LocationLink
    local def_result = (function(result)
      -- If there are multiple locations, usually the first entry would be what we are looking for,
      -- but heuristically prefer one that is more "far" (e.g., defined in a different file than requested)
      local requestUri = vim.tbl_get(params, 'textDocument', 'uri')
      table.sort(result, function(e1, e2)
        -- TODO: Consider line number as well to better determine distance.
        local dist1 = (e1.targetUri == requestUri) and 0 or 1
        local dist2 = (e2.targetUri == requestUri) and 0 or 1
        return dist1 > dist2
      end)
      return result[1]
    end)(vim.tbl_islist(result) and result or { result })

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
    vim.notify("PeekDefinition: " .. err, vim.log.levels.ERROR, {title = 'PeekDefinition'})
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


-------------
--- LSPstatus
-------------
function M.setup_lsp_status()
  local lsp_status = require('lsp-status')
  lsp_status.config({
    -- Avoid using use emoji-like or full-width characters
    -- because it can often break rendering within tmux and some terminals
    -- See $VIMPLUG/lsp-status.nvim/lua/lsp-status.lua
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
  if #vim.lsp.get_clients({bufnr = 0}) > 0 then
    return require('lsp-status').status()
  end
  return ''
end

-- Other LSP commands
-- :LspDebug, :CodeActions
function M._setup_lsp_commands()
  vim.cmd [[
    command! -nargs=0 LspDebug  :tab drop $HOME/.cache/nvim/lsp.log
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
      --see $VIMPLUG/fidget.nvim/lua/fidget/spinners.lua
      spinner = "zip",
    },
    window = {
      relative = "win",
      blend = 50,
    },
  }
end

----------------
--- trouble.nvim
----------------
function M.setup_trouble()
  require("trouble").setup {
    -- https://github.com/folke/trouble.nvim#setup
    mode = "document_diagnostics",
    auto_preview = false,
  }
end

----------------------------------------
--- Linting, and Code actions
----------------------------------------
function M.setup_null_ls()
  local null_ls = require("null-ls")
  local h = require("null-ls.helpers")

  -- Monkey-patching because of a performance bug on startup (jose-elias-alvarez/null-ls.nvim#1564)
  require('null-ls.client').retry_add = require('null-ls.client').try_add

  -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/CONFIG.md
  -- @see https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

  local executable = function(cmd)
    return vim.fn.executable(cmd) > 0
  end
  local cond_if_executable = function(cmd)
    return function() return executable(cmd) end
  end
  local _exclude_nil = function(tbl)
    return vim.tbl_filter(function(s) return s ~= nil end, tbl)
  end

  -- null-ls sources (mason.nvim installation is recommended)
  -- @see $VIMPLUG/null-ls.nvim/doc/BUILTINS.md
  -- @see $VIMPLUG/null-ls.nvim/lua/null-ls/builtins/
  local sources = {}
  do -- [[ diagnostics (linting) ]]
    -- python: pylint, flake8
    vim.list_extend(sources, {
      require('null-ls.builtins.diagnostics.pylint').with {
          method = null_ls.methods.DIAGNOSTICS_ON_SAVE,
          condition = function(utils)  ---@param utils ConditionalUtils
            -- https://pylint.pycqa.org/en/latest/user_guide/run.html#command-line-options
            return executable('pylint') and
              utils.root_has_file({ "pylintrc", ".pylintrc" })
          end,
      },
    })
  end

  -- See $VIMPLUG/null-ls.nvim/lua/null-ls/config.lua, defaults
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

    -- Use a border for the :NullLsLog window
    border = 'single',

    -- Debug mode: Use :NullLsLog for viewing log files (~/.cache/nvim/null-ls.log)
    debug = false,
  })

  -- Commands for LSP formatting. :LspFormat
  -- FormattingOptions: @see https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#formattingOptions
  vim.cmd [[
    command! LspFormatSync        lua vim.lsp.buf.format({timeout_ms = 5000})
  ]]
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
  M.setup_lsp_status()
  M.setup_navic()
  M.setup_fidget()
  M.setup_trouble()
  M.setup_null_ls()
end


-- Resourcing support
if ... == nil then
  M.setup_all()
end

return M
