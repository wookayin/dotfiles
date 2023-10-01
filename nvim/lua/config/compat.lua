-- Compatibility layer for vim lua APIs
-- Backport core lua APIs that does not exist in neovim 0.8.0 (from dev version)
-- see also
--   :HelpfulVersion


-- Compatibility layer for neovim < 0.9.0 (see neovim#22761)
---@diagnostic disable: deprecated
vim.treesitter.query.set = vim.treesitter.query.set or vim.treesitter.query.set_query
vim.treesitter.query.get = vim.treesitter.query.get or vim.treesitter.query.get_query
---@diagnostic enable: deprecated

-- Workaround for neovim 0.9.0+: Suppress deprecation warning
-- Many third-party plugins (still on 0.8.x API) need to migrate to the new treesitter API
if vim.fn.has('nvim-0.9') > 0 then
  vim.treesitter.query.get_node_text = vim.treesitter.get_node_text
  vim.treesitter.query.get_query = vim.treesitter.query.get
end
