--------------
-- Git plugins
--------------

local M = {}

function M.setup_fugitive()
  -- TODO: We still need to migrate a lot of configs from ~/.vimrc

  -- Keymaps related to :Git command
  local nmap = function(lhs)  -- nmap "lhs" "rhs", no opts, noremap
    return function(rhs) vim.keymap.set('n', lhs, rhs) end
  end
  local vim_cmd = function(x) return '<Cmd>' .. x .. '<CR>' end

  nmap "<leader>gc" (vim_cmd [[tab Git commit --verbose]]);
  nmap "<leader>gC" (vim_cmd [[tab Git commit --amend --verbose]]);
  nmap "<leader>gF" (vim_cmd [[tab Git fixup]]);

  nmap "<leader>gR" ':tab Git rebase -i --autosquash --autostash '

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
    -- Disable -F (exit on EOF) because we will autoclose the floaterm
    vim.fn['floaterm#new'](0, cmd .. " | less -+F", vim.empty_dict(), {
      name = 'git', autoclose = 1,
      title = " " .. cmd .. " ",
    })
  end, { nargs = '*' })

  -- Force-reload fugitive buffer upon enter, because it does not reload upon external changes.
  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = 'fugitive://*/.git//0/*',
    group = vim.api.nvim_create_augroup('fugitive-index-reload', { clear = true }),
    callback = function()
      M.reload_fugitive_index()
    end,
  })

  -- More git-related user commands
  M._setup_git_commands()
end

function M.setup_gitmessenger()
  --- https://github.com/rhysd/git-messenger.vim#variables

  -- Use git blame -w (ignore-whitespaces).
  vim.g.git_messenger_extra_blame_args = '-w'

  -- Display content diff as well in the popup window
  vim.g.git_messenger_include_diff = 'current'

  -- Use border for the popup window.
  vim.g.git_messenger_floating_win_opts = {
    border = 'single',
  }

  -- map <C-O>/<C-I> to jumping to older and Older(recent) commits, respectively
  -- (see rhysd/git-messenger.vim#3)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'gitmessengerpopup',
    group = vim.api.nvim_create_augroup('git_messenger_autocmd', { clear = true }),
    callback = function()
      vim.keymap.set('n', '<C-O>', 'o', { remap = true, buffer = true })
      vim.keymap.set('n', '<C-I>', 'O', { remap = true, buffer = true })
    end
  })
end

function M.setup_gitsigns()
  -- :help gitsigns-usage
  -- :help gitsigns-config
  ---@type Gitsigns.Config
  ---@diagnostic disable: missing-fields
  local gitsigns_config = {
    signcolumn = true,
    signs = {
      -- █ ▉ ▊ ▋ ▌ ▍ ▎ ▏ ┃│┆
      -- For highlights, see $DOTVIM/colors/xoria256-wook.vim
      add          = { text = '┃' },
      change       = { text = '┃' },
      topdelete    = { text = '‾' },
      delete       = { text = '_' },
      changedelete = { text = '┃' },
      untracked    = { text = '┆' },
    },
    signs_staged = {
      add          = { text = '█' },
      change       = { text = '█' },
      topdelete    = { text = '🮂' },
      delete       = { text = '🬭' },
      changedelete = { text = '█' },
    },
    sign_priority = 6,  -- Note: LSP diagnostics sign priority is 10~13
    -- numhl = true,
    current_line_blame_opts = {
      delay = 150,
      virt_text_pos = 'right_align',
      ignore_whitespace = true,
    },
    current_line_blame_formatter = '<abbrev_sha> <summary> - <author> <author_time>',
    diff_opts = {
      -- Use neovim's builtin diff (see diffopt in vimrc)
      internal = true,
      -- smarter diff algorithm that is semantically better
      algorithm = 'patience',
      -- Equivalent as git diff --indent-heuristic
      indent_heuristic = true,
      -- Use line matching algorithm (neovim#14537)
      linematch = vim.fn.has('nvim-0.9.0') > 0 and 60 or nil,
      ---@diagnostic disable: assign-type-mismatch
      -- Include whitespace-only changes in git hunks
      -- regardless of &diffopt (gitsigns.nvim#696)
      ignore_whitespace_change = false,
      ignore_blank_lines = false,
      ignore_whitespace = false,
      ignore_whitespace_change_at_eol = false,
      ---@diagnostic enable: assign-type-mismatch
    },
    on_attach = function(bufnr)
      vim.b[bufnr].gitsigns_attached = true

      local function map(mode, lhs, rhs, opts)
        opts = vim.tbl_extend('force', { remap = false, silent = true, buffer = bufnr }, opts or {})
        vim.keymap.set(mode, lhs, rhs, opts)
      end
      -- Navigation
      map('n', ']c', function() return vim.wo.diff and ']c' or '<Cmd>Gitsigns next_hunk<CR>' end,
        { expr = true, desc = "goto next hunk (or next diff)" })
      map('n', '[c', function() return vim.wo.diff and '[c' or '<Cmd>Gitsigns prev_hunk<CR>' end,
        { expr = true, desc = "goto previous hunk (or previous diff)" })
      -- Actions
      -- TODO: Also call reload_fugitive_index() after gitsigns operations (even if it's not on the "diff mode")
      map('n', '<leader>hs', '<cmd>Gitsigns stage_hunk<CR>')
      map('n', '<leader>hr', '<cmd>Gitsigns reset_hunk<CR>')
      map('v', '<leader>hs', function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
          { desc = 'Stage hunks on the selected range' })
      map('v', '<leader>hr', function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
          { desc = 'Reset hunks on the selected range' })
      map('n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>')
      map('n', '<leader>gU', '<cmd>Gitsigns reset_buffer_index<CR>')  -- Git unstage %
      map('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>')
      map('n', '<leader>hb', '<cmd>lua require"gitsigns".blame_line {full=true, ignore_whitespace=true}<CR>')
      map('n', '<leader>hm', '<leader>hb', { remap = true })
      map('n', '<leader>tb', '<cmd>Gitsigns toggle_current_line_blame<CR>')
      map('n', '<leader>hd', '<cmd>Gitsigns diffthis<CR>')                    -- Diff against stage
      map('n', '<leader>hD', '<cmd>lua require"gitsigns".diffthis("~")<CR>')  -- Diff against HEAD
      map('n', '<leader>td', '<cmd>Gitsigns toggle_deleted<CR>')
      -- Text object
      map('o', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
      map('x', 'ih', ':<C-U>Gitsigns select_hunk<CR>')

      -- Additional keymappings (actions) other than the suggested defaults
      map('n', '<leader>ha', '<leader>hs', { remap = true, desc = "Stage this hunk" })
      map('v', '<leader>ha', '<leader>hs', { remap = true, desc = "Stage hunks on the selected range" })
      map('n', '<leader>hh', '<cmd>Gitsigns toggle_linehl<CR>')
      map('n', '<leader>hw', '<cmd>Gitsigns toggle_word_diff<CR>')
    end,
    debug_mode = false,
  }
  ---@diagnostic enable: missing-fields
  require('gitsigns').setup(gitsigns_config)
  _G.gitsigns = require('gitsigns')

  -- When entering the buffer (out of external git events), gitsigns should be refreshed
  vim.api.nvim_create_autocmd('BufEnter', {
    pattern = '*',
    group = vim.api.nvim_create_augroup('gitsigns-refresh', { clear = true }),
    callback = function()
      if vim.b.gitsigns_attached then
        require("gitsigns").refresh()
      end
    end,
  })
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
    hooks = {
      ---@param ctx { symbol: string, layout_name: string }
      diff_buf_win_enter = function(bufnr, winid, ctx)
        -- see :help diffview-layouts
        if ctx.layout_name == 'diff4_mixed' then
          -- turn off 'diff' for the current version (ours) and local copy,
          -- as only the diff between base..incoming(theris) is useful.
          if ctx.symbol == 'a' or ctx.symbol == 'b' then
            vim.wo[winid].diff = false
          end
        end
      end,
    },
    default_args = {
      -- :DiffviewOpen --untracked-files=no
      DiffviewOpen = { '--untracked-files=no' },
    },
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

--- Create more custom git commands.
function M._setup_git_commands()
  --- :GitThreeWayDiff
  --- { HEAD, stage/index, working copy } with diff between HEAD v.s. index
  vim.api.nvim_create_user_command('GitThreeWayDiff', function()
    local cursor = vim.api.nvim_win_get_cursor(0)

    vim.cmd [[ tabnew % ]]
    -- turn off diff for all windows
    vim.cmd [[ diffoff! ]]
    local win = vim.api.nvim_get_current_win()  -- on a new tab
    vim.api.nvim_win_set_cursor(win, cursor)  -- preserve the same cursor location

    vim.cmd [[ aboveleft Gvdiff HEAD ]]  -- left: HEAD
    vim.fn.win_gotoid(win)
    vim.cmd [[ aboveleft Gvdiff ]]       -- middle: stage/index
    vim.fn.win_gotoid(win)
    vim.cmd [[ diffoff ]]                -- right: working copy (no diff)
  end, {})
end

--- Reload fugitive:// index buffer upon external edit including gitsigns.
--- See tpope/vim-fugitive#1517
function M.reload_fugitive_index()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local bufname = vim.api.nvim_buf_get_name(buf)
    local is_fugitive_index = vim.startswith(bufname, 'fugitive://') and string.find(bufname, '.git//0/')
    if is_fugitive_index then
      vim.api.nvim_buf_call(buf, function()
        -- Reload the git index buffer
        vim.cmd.doautocmd('BufReadCmd')
      end)
    end
  end
end

--- Get a human-readable ref name (e.g. master, master~1, remotes/origin/HEAD) for a commit hash,
--- from the output of `git name-rev`. Returns nil if the reference cannot be resolved,
--- or "undefined" if no named reference is found (i.e. dangling or detached commit).
--- This function may be called quite frequently (statusline), so needs to cache the result.
---@type function(sha: string, git_path?: string): string|nil
M.name_revision = (function()
  local cache = {}
  local function memoize(fn)
    return function(sha, git_path)
      local ret = (cache[git_path] or {})[sha]
      if ret then return ret[1] end

      ret = { fn(sha, git_path) }
      if git_path == nil then
        git_path = vim.fn.getcwd(0)
      end
      cache[git_path] = cache[git_path] or {}
      cache[git_path][sha] = ret
      return ret[1]
    end
  end
  vim.api.nvim_create_autocmd('User', {
    pattern = 'FugitiveChanged',
    group = vim.api.nvim_create_augroup('fugitive-revision-cache', { clear = true }),
    callback = function()
      -- invalidate all the cache on git operations
      for k, _ in pairs(cache) do cache[k] = nil end
    end,
  })

  return memoize(function(sha, git_path)
    local args = { "name-rev", sha, "--name-only" }
    local ret

    if git_path then
      git_path = vim.fn.FugitiveExtractGitDir(vim.fn.expand(git_path))
      ret = vim.fn.FugitiveExecute(args, git_path).stdout
    else
      ret = vim.fn.FugitiveExecute(args).stdout
    end
    ret = vim.trim(table.concat(ret, ''))
    if #ret == 0 then
      return nil
    else
      return ret
    end
  end)
end)()


-- Resourcing support
if ... == nil then
  M.setup_fugitive()
  M.setup_diffview()
  M.setup_gitsigns()

  M._setup_git_commands()
end

return M
