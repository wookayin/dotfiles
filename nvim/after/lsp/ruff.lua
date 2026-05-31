-- extends $VIMPLUG/nvim-lspconfig/lsp/ruff.lua

-- The "ruff" Language Server
-- https://docs.astral.sh/ruff/editors/settings/
local init_options = {
  settings = {
    fixAll = true,
    organizeImports = false, -- in favor of Conform (:Format ruff_organize_imports)

    -- NOTE: The lint/format rules for the "ruff LSP" here are meant to be a sensible default
    -- setting in the editor level; the ruff CLI (`ruff check`) still may give linting errors.
    -- Per-project lint/format config should be configured in pyproject.toml.
    -- https://docs.astral.sh/ruff/rules/
    lint = {
      preview = true, -- Use experimental features by default
      ignore = {
        "C408", -- unnecessary-collection-call  e.g. dict(foo=bar)
        "E111", -- indentation-with-invalid-multiple
        "E114", -- indentation-with-invalid-multiple-comment
        "E402", -- module-import-not-at-top-of-file
        "E501", -- line-too-long
        "E702", -- multiple-statements-on-one-line-semicolon
        "E731", -- lambda-assignment
        -- These are still checked by ruff, but should be HINT rather than WARN (see below)
        -- "F401", -- unused-import
        -- "F841", -- unused-variable
      },
      -- [Override diagnostic severity]
      -- Ruff reports most of the lint violations (exceptions are syntax errors) as WARN level,
      -- but some lint rules are better surfaced at HINT/INFO level.
      -- This is a field recognized not by the ruff LSP, but by our custom diagnostics LSP handlers.
      _severity_overrides = { ---@type table<string, lsp.DiagnosticSeverity>
        ["I001"] = vim.diagnostic.severity.HINT,  -- unsorted-imports

        ["F401"] = vim.diagnostic.severity.WARN,  -- unused-import
        ["F841"] = vim.diagnostic.severity.WARN,  -- unused-variable
        ["RUF059"] = vim.diagnostic.severity.WARN,  -- unused-unpacked-variable

        ["C4"] = vim.diagnostic.severity.HINT,  -- flake8-comprehensions
        ["PLC"] = vim.diagnostic.severity.HINT,  -- pylint conventions
        ["PLR"] = vim.diagnostic.severity.HINT,  -- pylint refactors
        ["PLW"] = vim.diagnostic.severity.WARN,  -- pylint warnings
        ["UP"] = vim.diagnostic.severity.HINT,  -- pyupgrade
      },
    },
    format = {
      preview = true,
    },
    -- Configuration files (e.g. pyproject.toml) takes priority over editor (lspconfig) settings
    configurationPreference = "filesystemFirst",
  },
}

local on_init = function(client, _)
  if client.server_capabilities then
    -- Disable ruff hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
    -- Disable ruff formatting in favor of Conform (ruff_format)
    -- NOTE: ruff-lsp's formatting is a bit buggy, doesn't respect indent_size
    client.server_capabilities.documentFormattingProvider = false
  end
end


---@param code string|integer
---@return lsp.DiagnosticSeverity|nil
local function resolve_severity(code)
  code = tostring(code)
  local severity_overrides = init_options.settings.lint._severity_overrides
  if severity_overrides[code] then return severity_overrides[code] end
  for prefix, severity in pairs(severity_overrides) do
    if vim.startswith(code, prefix) then return severity end
  end
  return nil
end
---@param diags lsp.Diagnostic[]
local function patch_severities(diags)
  for _, diag in ipairs(diags) do
    local new_severity = resolve_severity(diag.code)
    if new_severity then
      diag.severity = new_severity
    end
  end
end


return {
  init_options = init_options,
  on_init = on_init,
  handlers = { ---@type table<string, lsp.Handler>
    ---@param params lsp.PublishDiagnosticsParams
    ["textDocument/publishDiagnostics"] = function(err, params, ctx, config)  -- notification
      if params and params.diagnostics then
        patch_severities(params.diagnostics)
      end
      return vim.lsp.handlers["textDocument/publishDiagnostics"](err, params, ctx, config)
    end,
    ---@param result lsp.DocumentDiagnosticReport
    ["textDocument/diagnostic"] = function(err, result, ctx, config)  -- response
      if result and result.items then
        patch_severities(result.items)
      end
      return vim.lsp.handlers["textDocument/diagnostic"](err, result, ctx, config)
    end,
  },
  capabilities = {
    general = {
      -- pyright uses utf-16, and ruff uses utf-8 by default.
      -- To avoid 'multiple different client offset_encodings ...', we tell ruff to use 'utf-16' only
      -- https://github.com/astral-sh/ruff/issues/14483
      positionEncodings = { "utf-16" },
    },
  },
}
