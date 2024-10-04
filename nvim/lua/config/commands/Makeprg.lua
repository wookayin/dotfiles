-- This would override :Makeprg, :MakeprgLocal defined in vimrc

local M = {}

-- Define commands upon sourcing
-- :Makeprg, :MakeprgGlobal, :MakeprgLocal
vim.api.nvim_create_user_command(
  'Makeprg', function(opts) M.SetMakeprg(opts.args) end,
  { nargs = '?', desc = 'Change &g:makeprg or &l:makeprg.' })
vim.api.nvim_create_user_command(
  'MakeprgGlobal', function(opts) M.SetMakeprg(opts.args, "g") end,
  { nargs = '?', desc = 'Change (global) &l:makeprg.' })
vim.api.nvim_create_user_command(
  'MakeprgLocal', function(opts) M.SetMakeprg(opts.args, "l") end,
  { nargs = '?', desc = 'Change (local) &l:makeprg.' })


function M.SetMakeprg(args, mode)
  if mode == nil then  -- auto determine, 'l' iff &l:makeprg is set
    mode = string.len(vim.opt_local.makeprg:get() or "") > 0 and 'l' or 'g'
  end

  -- mode: 'g' or 'l'
  local vim_opt = (mode == 'g') and vim.opt_global or vim.opt_local
  local confirm_change = function()
    print(string.format("%s:makeprg = ", mode) .. vim_opt.makeprg:get())
  end

  args = args or ""
  if args ~= "" then
    vim_opt.makeprg = args
    confirm_change()
    return
  end

  local prompt = string.format("Enter the new &%s:makeprg command", mode)
  if mode == 'l' then
    prompt = prompt .. string.format(' (for the buffer %s)', vim.fn.bufname())
  end
  prompt = prompt .. " >"

  local CANCEL_SENTINEL = "___!!!@@@CANCELLED@@@!!!___"
  vim.ui.input({
    prompt = prompt,
    default = vim_opt.makeprg:get(),
    cancelreturn = CANCEL_SENTINEL,  -- see dressing.nvim#72
  }, function(new_value)
    if new_value == CANCEL_SENTINEL then
      return  -- Interrupted or canceled, different from ""
    end
    new_value = vim.trim(new_value or "")
    if new_value ~= "" or mode == 'l' then
      -- Change either g:makeprg or l:makeprg
      vim_opt.makeprg = new_value
      -- Save to history so that any previous changes can be restored
      vim.fn.histadd("cmd", (mode == 'g' and "MakeprgGlobal" or "MakeprgLocal") .. " " .. new_value)
    end
    confirm_change()
  end)
end

return M
