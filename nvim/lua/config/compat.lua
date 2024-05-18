-- Compatibility layer for vim lua APIs
-- Backport core lua APIs that does not exist in neovim 0.8.0 (from dev version)
-- see also
--   :HelpfulVersion
---@diagnostic disable: deprecated

local has = function(feature) return vim.fn.has(feature) > 0 end


-- Compatibility layer for neovim < 0.9.0 (see neovim#22761)
vim.treesitter.query.set = vim.treesitter.query.set or vim.treesitter.query.set_query
vim.treesitter.query.get = vim.treesitter.query.get or vim.treesitter.query.get_query

-- Workaround for neovim 0.9.0+: Suppress deprecation warning
-- Many third-party plugins (still on 0.8.x API) need to migrate to the new treesitter API
if vim.fn.has('nvim-0.9') > 0 then
  vim.treesitter.query.get_node_text = vim.treesitter.get_node_text
  vim.treesitter.query.get_query = vim.treesitter.query.get
end

-- for nvim < 0.9.0
if vim.treesitter.language.get_lang == nil then
  vim.treesitter.language.get_lang = function(ft)
    return require("nvim-treesitter.parsers").ft_to_lang(ft)
  end
end

-- for nvim < 0.10
if not has('nvim-0.10') and vim.lsp.get_clients == nil then
  vim.lsp.get_clients = vim.lsp.get_active_clients
end

-- for nvim >= 0.11, against deprecated warnings (until plugins catch up)
if has('nvim-0.11') then
  vim.tbl_islist = vim.islist
end
