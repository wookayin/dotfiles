local M = {}

--- Configure conform.nvim formatters
function M.setup_conform()

  _G.conform = require("conform")
  require("conform").setup {
    formatters_by_ft = {}, -- see below
  }

  -- Configure filetypes and formatters
  -- Do not configure if LSP provides a good formatting (e.g., rustfmt)
  local formatter_opts = require("conform").formatters
  local one_of = vim.tbl_flatten
  local cf = {}

  cf.lua = function()
    formatter_opts["stylua"] = {
      prepend_args = { "--indent-type", "Spaces", "--indent-width", tostring(2) },
    }
    return { "stylua" }
  end
  cf.python = function()
    return { "isort", "yapf" }
  end
  cf.sh = function()
    formatter_opts["shfmt"] = {
      prepend_args = function(ctx) return { "--indent", tostring(vim.bo[ctx.buf].shiftwidth) } end,
    }
    return { "shfmt" }
  end
  cf.bash = cf.sh
  cf.zsh = cf.sh
  cf.javascript = { one_of({ "prettierd", "prettier" }) }
  cf.typescript = { one_of({ "prettierd", "prettier" }) }

  for ft, v in pairs(cf) do
    if type(v) == "function" then v = v() end
    require("conform").formatters_by_ft[ft] = v
  end

end


if RC and RC.should_resource() then
  M.setup_conform()
end

return M
