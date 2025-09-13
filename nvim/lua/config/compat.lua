-- Compatibility layer for vim lua APIs
-- Backport core lua APIs that does not exist in older versions of neovim (from stable/dev version)
-- See also
--   :HelpfulVersion
---@diagnostic disable: deprecated

local has = function(feature) return vim.fn.has(feature) > 0 end


-- for nvim < 0.10
if vim.lsp.get_clients == nil then
  vim.lsp.get_clients = vim.lsp.get_active_clients
end

-- for nvim >= 0.11, against deprecated warnings (until plugins catch up)
if has('nvim-0.11') then
  vim.tbl_islist = vim.islist
end

-- nvim 0.11: vim.highlight => vim.hl (does not exist in neovim 0.10)
if vim.hl == nil then
  vim.hl = vim.highlight
end

-- Nvim 0.11: vim.diagnostic.jump() deprecated vim.diagnostic.goto_{next,prev}.
if vim.diagnostic.jump ~= nil then  -- nvim >= 0.11+
  vim.diagnostic.goto_prev = function(opts)
    vim.diagnostic.jump(vim.tbl_deep_extend('force', { count = -1, float = true }, opts or {}))
  end
  vim.diagnostic.goto_next = function(opts)
    vim.diagnostic.jump(vim.tbl_deep_extend('force', { count = 1, float = true }, opts or {}))
  end
end

-- deprecated in nvim 0.12, use the same behavior (exclude false and nil)
if has('nvim-0.12') then
  vim.tbl_flatten = function(t)
    return vim.iter(t):filter(function(truthy) return truthy end):flatten(math.huge):totable()
  end
end
