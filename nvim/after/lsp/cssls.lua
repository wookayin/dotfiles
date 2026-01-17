-- extends $VIMPLUG/nvim-lspconfig/lsp/cssls.lua

return {
  settings = {
    css = {
      validate = true,
      lint = {
        unknownAtRules = 'ignore', -- e.g. @apply
      },
    },
    less = {
      validate = true,
    },
    scss = {
      validate = true,
    }
  },
}
