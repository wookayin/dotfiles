--------------
-- Git plugins
--------------

local M = {}

function M.setup_diffview()
  -- :help diffview.defaults
  -- :help diffview-config

  require('diffview').setup {
    view = {
      -- Use 4-way diff (ours, base, theirs; local) for fixing conflicts
      merge_tool = {
        layout = "diff4_mixed",
        disable_diagnostics = true,
      },
    },
    default_args = {
      -- :DiffviewOpen --untracked-files=no
      DiffviewOpen = { '--untracked-files=no' },
    }
  }

  vim.cmd [[
    " :GHistory <files>
    command! -nargs=* -complete=file GHistory   DiffviewFileHistory <args>
    " :GDiff <revision>     to HEAD
    command! -nargs=* -complete=customlist,DiffviewCmdCompletion  GDiff  DiffviewOpen <args>
    " :GShow <revision>
    command! -nargs=+ -complete=customlist,DiffviewCmdCompletion  GShow  DiffviewOpen <args>^1..<args>

    " cmd completion functions for aliased commands.
    function! DiffviewCmdCompletion(argLead, cmdLine, curPos)
      return luaeval("require'diffview'.completion("
            \ . "vim.fn.eval('a:argLead'),"
            \ . "vim.fn.eval('a:cmdLine'),"
            \ . "vim.fn.eval('a:curPos'))")
    endfunction
  ]]

  local completers = require('diffview').completers
  completers.GDiff = completers.DiffviewOpen
  completers.GShow = completers.DiffviewOpen
end

if pcall(require, 'diffview') then
  M.setup_diffview()
end

pcall(function() RC.git = M end)

return M
