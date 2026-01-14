-- extends $VIMPLUG/nvim-lspconfig/lsp/ruff.lua

-- https://github.com/astral-sh/ruff-lsp#settings
-- https://github.com/astral-sh/ruff-lsp/blob/main/ruff_lsp/server.py
-- Note: use pyproject.toml to configure ruff per project.
local init_options = {
  settings = {
    fixAll = true,
    organizeImports = false, -- in favor of Conform (:Format ruff_organize_imports)
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

return {
  init_options = init_options,
  on_init = on_init,
  capabilities = {
    general = {
      -- pyright uses utf-16, and ruff uses utf-8 by default.
      -- To avoid 'multiple different client offset_encodings ...', we tell ruff to use 'utf-16' only
      -- https://github.com/astral-sh/ruff/issues/14483
      positionEncodings = { "utf-16" },
    },
  },
}
