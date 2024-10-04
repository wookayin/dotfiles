-- utils.term_utils

---@class utils.term_utils.TermWin
---@field win integer
---@field opts table<string, any>
local TermWin = {}
TermWin._instances = {}

---@return utils.term_utils.TermWin
function TermWin.getinstance(name, opts)
  assert(name)
  if not TermWin._instances[name] then
    TermWin._instances[name] = TermWin.new(opts)
  end
  return TermWin._instances[name]
end

---@return utils.term_utils.TermWin
function TermWin.new(opts)
  local self = setmetatable({}, { __index = TermWin })
  self.win = -1
  self.opts = vim.tbl_deep_extend("force", {
    split = "botright",
    rows = 10,
  }, opts or {})
  return self
end

function TermWin.open(self)
  vim.cmd.split { mods = { split = self.opts.split }, range = { self.opts.rows } }
  self.win = vim.api.nvim_get_current_win()
  vim.wo[self.win].winfixheight = true
  vim.cmd [[ wincmd p ]]
  return self.win
end

function TermWin.run(self, cmd)
  self.win = vim.api.nvim_win_is_valid(self.win) and self.win or self:open()
  vim.api.nvim_win_call(self.win, function()
    local old_buf = vim.api.nvim_win_get_buf(self.win)
    vim.cmd.term { args = { cmd } }
    vim.cmd.stopinsert()  -- work around a bug: startinsert autocmd done on a wrong window
    vim.cmd [[ norm G ]]  -- put the cursor below so that it can auto-scroll

    if vim.bo[old_buf].buftype == "terminal" then
      vim.api.nvim_buf_delete(old_buf, { force = true })
    end
  end)
end

function TermWin.focus(self)
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_set_current_win(self.win)
  end
end

function TermWin.close(self)
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
end

return {
  TermWin = TermWin,
}
