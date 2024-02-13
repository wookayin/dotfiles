-- config/statuscol.lua
-- Based on LazyVim: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/ui.lua

local M = {}

vim.opt.signcolumn = 'yes:1'

-- &statuscolumn is supported in neovim 0.9.0+
if vim.fn.exists('&statuscolumn') == 0 then
  return false
end

vim.opt.statuscolumn = [[%!v:lua.require'config.statuscolumn'.statuscolumn()]]


--- The &statuscolumn function.
--- Shows gitsigns or fold, and mark or diagnostics.
function M.statuscolumn()
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local is_file = vim.bo[buf].buftype == ""
  local show_signs = vim.wo[win].signcolumn ~= "no"
  local fold_enabled = vim.wo[win].foldenable

  local components = { } ---@type table<string, string>

  if show_signs then
    ---@type Sign?, Sign?, Sign?
    local sign, gitsign, fold
    for _, s in ipairs(M.get_signs(buf, vim.v.lnum)) do
      if s.name and vim.startswith(s.name, "GitSigns") then
        -- prefer non-staged signs (GitSigns*) over GitSignStaged*
        if (s.name or ""):match("^GitSignsStaged") then
          gitsign = gitsign or s
        else
          gitsign = s
        end
      else
        -- show only the sign with the highest priority
        sign = s
      end
    end
    if vim.v.virtnum ~= 0 then
      sign = nil
    end
    vim.api.nvim_win_call(win, function()
      if vim.fn.foldclosed(vim.v.lnum) >= 0 then
        fold = { text = vim.opt.fillchars:get().foldclose or "", texthl = "Folded" }
      end
    end)
    components.git_or_fold = is_file and M.icon(fold or gitsign, 1) or ""
    components.git = is_file and M.icon(gitsign, 1) or ""
    components.fold = is_file and fold_enabled and (fold and M.icon(fold, 1) or "%C") or ""
    components.mark_or_sign = M.icon(M.get_mark(buf, vim.v.lnum) or sign, 2)
  end

  -- Numbers in Neovim are weird
  -- They show when either number or relativenumber is true
  local is_num = vim.wo[win].number
  local is_relnum = vim.wo[win].relativenumber
  if (is_num or is_relnum) and vim.v.virtnum == 0 then
    if vim.v.relnum == 0 then
      components.line_num = is_num and "%l" or "%r" -- the current line
    else
      components.line_num = is_relnum and "%r" or "%l" -- other lines
    end
    components.line_num = "%=" .. components.line_num -- right align
    components.line_num = components.line_num .. " "
  end

  _G.components = components
  return table.concat({
    -- components.fold or "",
    components.git_or_fold or "",
    components.mark_or_sign or "",
    components.line_num or "",
  }, "")
end


---@alias Sign { name:string, text:string, texthl:string, priority:number }

-- Returns a list of regular and extmark signs sorted by priority (low to high)
---@return Sign[]
---@param buf integer
---@param lnum integer
function M.get_signs(buf, lnum)
  -- Get regular signs
  ---@type Sign[]
  local signs = {}

  if vim.fn.has("nvim-0.10") == 0 then
    -- Only needed for Neovim <0.10
    -- Newer versions include legacy signs in nvim_buf_get_extmarks
    for _, sign in ipairs(vim.fn.sign_getplaced(buf, { group = "*", lnum = lnum })[1].signs) do
      local ret = vim.fn.sign_getdefined(sign.name)[1] --[[@as Sign]]
      if ret then
        ret.priority = sign.priority
        signs[#signs + 1] = ret
      end
    end
  end

  -- Get extmark signs
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1,
    { lnum - 1, 0 },
    { lnum - 1, -1 },
    { details = true, type = "sign" }
  )
  for _, extmark in pairs(extmarks) do
    -- extmark { extmark_id, row, col, detail }
    local detail = extmark[4]
    signs[#signs + 1] = {
      name = detail.sign_hl_group or "",
      text = detail.sign_text,
      texthl = detail.sign_hl_group,
      priority = detail.priority,
    }
  end

  -- Sort by priority
  table.sort(signs, function(a, b)
    return (a.priority or 0) < (b.priority or 0)
  end)

  return signs
end

---@return Sign?
---@param buf integer
---@param lnum integer
function M.get_mark(buf, lnum)
  local marks = vim.fn.getmarklist(buf)
  vim.list_extend(marks, vim.fn.getmarklist())
  for _, mark in ipairs(marks) do
    if mark.pos[1] == buf and mark.pos[2] == lnum and mark.mark:match("[a-zA-Z]") then
      return { text = mark.mark:sub(2), texthl = "DiagnosticHint" }
    end
  end
end

---@param sign? Sign
---@param len integer
function M.icon(sign, len)
  sign = sign or {}
  assert(len, 'len must be given explicitly')
  local text = vim.fn.strcharpart(sign.text or "", 0, len) ---@type string
  text = text .. string.rep(" ", len - vim.fn.strchars(text))
  return sign.texthl and ("%#" .. sign.texthl .. "#" .. text .. "%*") or text
end

return M
