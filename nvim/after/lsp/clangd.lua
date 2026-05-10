return {
  -- Make sure to use utf-8 offset. clangd defaults to utf-16 (see jose-elias-alvarez/null-ls.nvim#429)
  -- against "multiple different client offset_encodings detected for buffer" error
  capabilities = {
    offsetEncoding = 'utf-8',
  }
}
