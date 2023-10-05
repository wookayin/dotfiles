--------------
-- Git plugins
--------------

local M = {}

function M.setup_fugitive()
  -- TODO: We still need to migrate a lot of configs from ~/.vimrc

  local nmap = function(lhs)  -- nmap "lhs" "rhs", no opts, noremap
    return function(rhs) vim.keymap.set('n', lhs, rhs) end
  end
  local vim_cmd = function(x) return '<Cmd>' .. x .. '<CR>' end

  nmap "<leader>gc" (vim_cmd [[tab Git commit --verbose]]);
  nmap "<leader>gC" (vim_cmd [[tab Git commit --amend --verbose]]);


  --[[ Utilities commands for git, using terminal windows ]]
  local command_alias = function(lhs)
    return function(rhs) vim.fn.CommandAlias(lhs, rhs) end
  end

  -- :GDiffTerm, :gd, :gdc
  command_alias "gd"  "GDiffTerm"
  command_alias "gdc" "GDiffTerm --cached"
  vim.api.nvim_create_user_command("GDiffTerm", function(e)
    local args = vim.fn.expandcmd(vim.trim(e.args))  -- supports '%'
    local cmd = "git diff --color " .. args
    if vim.fn.executable('delta') > 0 then cmd = cmd .. ' | delta ' end
    -- Disable -F (exit on EOF) because we will autoclose the floaterm
    vim.fn['floaterm#new'](0, cmd .. " | less -+F", vim.empty_dict(), {
      name = 'git', autoclose = 1,
      title = " " .. cmd .. " ",
    })
  end, { nargs = '*' })

end

function M.setup_gitsigns()
  -- :help gitsigns-usage
  -- :help gitsigns-config

  require('gitsigns').setup {
    signs = {
      -- For highlights, see $DOTVIM/colors/xoria256-wook.vim
      add          = {hl = 'GitSignsAdd'   , text = '┃', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
      change       = {hl = 'GitSignsChange', text = '┃', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
      delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
      topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
      changedelete = {hl = 'GitSignsChange', text = '┃', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
    },
    signcolumn = true,
    current_line_blame_opts = {
      delay = 150,
      virt_text_pos = 'right_align',
      ignore_whitespace = true,
    },
    diff_opts = {
      -- Use neovim's builtin diff (see diffopt in vimrc)
      internal = true,
      -- smarter diff algorithm that is semantically better
      algorithm = 'patience',
      -- Equivalent as git diff --indent-heuristic
      indent_heuristic = true,
      -- Use line matching algorithm (neovim#14537)
      linematch = vim.fn.has('nvim-0.9.0') > 0 and 60 or nil,
      -- Include whitespace-only changes in git hunks
      -- regardless of &diffopt (gitsigns.nvim#696)
      ignore_whitespace_change = false,
      ignore_blank_lines = false,
      ignore_whitespace = false,
      ignore_whitespace_change_at_eol = false,
    },
    on_attach = function(bufnr)
      local function map(mode, lhs, rhs, opts)
        opts = vim.tbl_extend('force', {noremap = true, silent = true}, opts or {})
        vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
      end
      -- Navigation
      map('n', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", {expr=true})
      map('n', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", {expr=true})
      -- Actions
      map('n', '<leader>hs', '<cmd>Gitsigns stage_hunk<CR>')
      map('n', '<leader>hr', '<cmd>Gitsigns reset_hunk<CR>')
      map('v', '<leader>hs', '<cmd>lua require"gitsigns".stage_hunk({ vim.fn.line("."), vim.fn.line("v") })<CR>')
      map('v', '<leader>hr', '<cmd>lua require"gitsigns".reset_hunk({ vim.fn.line("."), vim.fn.line("v") })<CR>')
      map('n', '<leader>hS', '<cmd>Gitsigns stage_buffer<CR>')
      map('n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>')
      map('n', '<leader>hR', '<cmd>Gitsigns reset_buffer<CR>')
      map('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>')
      map('n', '<leader>hb', '<cmd>lua require"gitsigns".blame_line {full=true, ignore_whitespace=true}<CR>')
      map('n', '<leader>tb', '<cmd>Gitsigns toggle_current_line_blame<CR>')
      map('n', '<leader>hd', '<cmd>Gitsigns diffthis<CR>')                    -- Diff against stage
      map('n', '<leader>hD', '<cmd>lua require"gitsigns".diffthis("~")<CR>')  -- Diff against HEAD
      map('n', '<leader>td', '<cmd>Gitsigns toggle_deleted<CR>')
      -- Text object
      map('o', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      map('x', 'ih', ':<C-U>Gitsigns select_hunk<CR>')

      -- Additional keymappings (actions) other than the suggested defaults
      map('n', '<leader>ha', '<leader>hs', { noremap = false })
      map('v', '<leader>ha', '<leader>hs', { noremap = false })
      map('n', '<leader>hh', '<cmd>Gitsigns toggle_linehl<CR>')
      map('n', '<leader>hw', '<cmd>Gitsigns toggle_word_diff<CR>')
    end
  }
  _G.gitsigns = require('gitsigns')
end

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

  _G.diffview = require('diffview')
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup_fugitive()
  M.setup_diffview()
  M.setup_gitsigns()
end

(RC or {}).git = M
return M
