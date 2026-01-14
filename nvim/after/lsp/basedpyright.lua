-- extends $VIMPLUG/nvim-lspconfig/lsp/basedpyright.lua
return {
  settings = {
    python = {
      -- Always use the current python in $PATH (the current conda/virtualenv).
      -- NOTE: python.pythonPath (not basedpyright.pythonPath), see the basedpyright docs
      pythonPath = vim.fn.exepath("python3"),
    },
    basedpyright = {
      -- in favor of ruff's import organizer
      disableOrganizeImports = true,
      -- use auto-import (which is also by default)
      autoImportCompletions = true,

      -- NOTE: the "discouraged settings" here will be ignored if the project root contains
      -- either a pyproject.toml ([tool.pyright]) or pyrightconfig.json configuration file.
      -- https://docs.basedpyright.com/latest/configuration/config-files/#overriding-language-server-settings
      -- https://docs.basedpyright.com/latest/configuration/language-server-settings/#discouraged-settings
      analysis = {
        typeCheckingMode = "standard",
        -- see https://docs.basedpyright.com/latest/usage/import-resolution/#configuring-your-python-environment
        -- see https://github.com/microsoft/pyright/blob/main/docs/import-resolution.md#resolution-order
        extraPaths = { "./python" },
      },

      inlayHints = {
        callArgumentNames = true,
        callArgumentNamesMathcing = false,
        functionReturnTypes = true,
        variableTypes = true,
        genericTypes = true,  --(override)
      },
    },
  },
}
