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

  M._setup_command()
end


local make_range = function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      ["start"] = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  return range
end

-- Define :Format and :ConformFormat commands.
function M._setup_command()
  local Format = function(args, lsp_fallback)
    local range = make_range(args)
    local ret = require("conform").format({
      bufnr = 0,
      lsp_fallback = lsp_fallback,
      range = range,
      formatters = #args.fargs > 0 and args.fargs or nil,
    })
    if not ret then
      local msg = string.format(
        "No %s formatters are available %s filetype `%s`.\n" ..
        "Try %s to see more information.",
        lsp_fallback and "conform or LSP" or "conform",
        range and "for range formatting on" or "for", vim.bo.filetype,
        lsp_fallback and "`:ConformInfo` or `:LspInfo`" or "`:ConformInfo`")
      vim.notify(msg, vim.log.levels.WARN, { title = "config.formatting" })
    end
  end

  local complete = function()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.tbl_map(function(formatter)
      return formatter.name
    end, require("conform").list_formatters(bufnr))
  end

  vim.api.nvim_create_user_command("Format",
    function(args) return Format(args, true) end, {
    nargs = "*", range = true, complete = complete,
    desc = "format the current buffer using conform and LSP.",
  })
  vim.api.nvim_create_user_command("ConformFormat",
    function(args) return Format(args, false) end, {
    nargs = "*", range = true, complete = complete,
    desc = "format the current buffer using conform only (no LSP fallback).",
  })
end


if RC and RC.should_resource() then
  M.setup_conform()
end

return M
