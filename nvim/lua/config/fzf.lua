------------
-- fzf + lua
------------

-- https://github.com/ibhagwan/fzf-lua, replaces fzf.vim

local M = {}

local function extend(lhs)
  return function(rhs) return vim.tbl_deep_extend("force", lhs, rhs) end
end

function M.setup()
  local defaults = require('fzf-lua.defaults').defaults
  local FZF_VERSION = require('fzf-lua.utils').fzf_version({})

  -- fzf-lua.setup(opts)
  local opts = {
    keymap = {
      -- 'builtin' means keymap for the neovim's terminal buffer (tmap <buffer>)
      builtin = extend(defaults.keymap.builtin) {
        ["<Esc>"] = "abort",
        ["<C-/>"] = "toggle-preview",
        ["<C-_>"] = "toggle-preview",
      },
      -- 'fzf' means keymap that is directly fed to the fzf process (fzf --bind)
      fzf = extend(defaults.keymap.fzf) {
        ["ctrl-/"] = "toggle-preview",
      },
    },
    fzf_opts = { -- global fzf opts to apply by default
      ["--info"] = FZF_VERSION >= 0.42 and "inline-right" or nil,
      ["--scrollbar"] = '▌',  -- use slightly thicker scrollbar
    },
    winopts = {
      width = 0.90,
      height = 0.80,
      preview = {
        vertical = "down:45%",
        horizontal = "right:50%",
        layout = "flex",
      },
      on_create = function()
        -- Some (global) terminal keymaps should be disabled for fzf-lua, see GH-871
        local keys_passthrough = { '<C-e>', '<C-y>' }
        local bufnr = vim.api.nvim_get_current_buf()
        for _, key in ipairs(keys_passthrough) do
          vim.keymap.set('t', key, key, { buffer = bufnr, remap = false, silent = true, nowait = true })
        end
      end,
    },
  }

  -- Customize builtin finders
  opts.autocmds = {
    winopts = { preview = { layout = "vertical", vertical = "down:33%" } },
  }

  opts.grep = {
    keymap = {
      fzf = {
        -- ctrl-q: Send all the result shown in the fzf to quickfix
        -- Note: since using the default action, it will instead jump to the result if #entries == 1
        -- Note, this can be VERY slow if #entires is HUGE; to be improved
        ["ctrl-q"] = "select-all+accept",
      }
    },
    copen = "horizontal copen", -- see #712
  }

  -- insert-mode completion: turn on preview by default
  opts.complete_file = {
    previewer = "default",
    winopts = { preview = { hidden = "nohidden" } },
  }

  require('fzf-lua').setup(opts)


  ---[[ Highlights ]]
  ---https://github.com/ibhagwan/fzf-lua#highlights
  require("utils.rc_utils").RegisterHighlights(function()
    vim.cmd [[
      hi!      FzfLuaNormal guibg=#151b21
      hi!      FzfLuaPmenu  guibg=#151515
      hi! link FzfLuaBorder FzfLuaNormal
    ]]
  end)

  ---[[ Commands ]]
  local command_alias = vim.fn.CommandAlias
  command_alias("FL", "FzfLua")

  local command = function(name, opts, rhs)
    vim.api.nvim_create_user_command(name, rhs, opts)
    return {
      alias = function(self, lhs, ...) command_alias(lhs, name, ...); return self; end
    }
  end
  local fzf = require("fzf-lua")
  local empty_then_nil = function(x) return x ~= "" and x or nil; end
  -- wrap a fzf-lua provider to a neovim user_command function
  -- with the (optional) argument set as the default fzf query.
  local bind_query = function(fzf_provider)
    return function(e)
      fzf_provider({ query = empty_then_nil(vim.trim(e.args)) })
    end
  end

  -- Finder (fd, rg, grep, etc.)
  -- Note: fzf-lua grep uses rg internally
  command("Files", { nargs = "?", complete = "dir", desc = "FzfLua files" }, function(e)
    fzf.files({ cwd = empty_then_nil(vim.trim(e.args)) })
  end)
  command("History", {}, "FzfLua oldfiles"):alias("H")
  command("Grep", { nargs = "?", bang = true, desc = "FzfLua grep" }, function(e)
    local args = vim.trim(e.args:gsub('\n', ''))
    if not e.bang then
      fzf.grep({ search = args })
    else
      fzf.live_grep({ search = args })
    end
  end)
  command_alias("Rg", "Grep")
  command("LiveGrep", { nargs = "?", desc = "FzfLua live_grep" }, function(e)
    fzf.live_grep({ search = vim.trim(e.args) })
  end)
  if vim.fn.executable("rg") == 0 then
    local msg = "rg (ripgrep) not found. Try `dotfiles install rg`."
    vim.notify(msg, vim.log.levels.WARN, { title = "config.fzf" })
  end
  command_alias("RG", "LiveGrep")
  -- keymaps (grep): CTRL-g, <leader>rg
  vim.keymap.set('n', '<C-g>', '<cmd>LiveGrep<CR>')
  vim.keymap.set('n', '<leader>rg', function()
    fzf.grep({ search = vim.fn.expand("<cword>") })
  end, { desc = ':Grep with <cword>' })
  vim.keymap.set('x', '<C-g>', '<leader>rg', { remap = true, silent = true,
    desc = ':Grep with visual selection' } )
  vim.keymap.set('x', '<leader>rg', [["gy:Grep <C-R>g<CR>]], { silent = true,
    desc = ':Grep with visual selection' } )


  -- Git providers
  command("Commits", {}, "FzfLua git_commits")  -- for the CWD. TODO: Support file arg
  command("BCommits", {}, "FzfLua git_bcommits")  -- for the buffer.
  command("GitStatus", { nargs = 0 }, "FzfLua git_status"
    ):alias("GStatus"):alias("GS")
  command("GitFiles", { nargs = "?", bang = true, complete = "dir", desc = "FzfLua git_files" }, function(e)
    if e.args == "?" then  -- GFiles?
      return vim.cmd [[ GitStatus ]]
    end
    local opts = { cwd = empty_then_nil(e.args) }
    if e.bang then  -- GFiles!: include untracked files as well
      opts.cmd = "git ls-files --exclude-standard --cached --modified --others --deduplicate"
    end
    -- Note: Unlike junegunn's GitFiles, it no longer accepts CLI flag. Use Lua API instead
    fzf.git_files(opts)
  end):alias("GFiles", { register_cmd = true }):alias("GF")
  command("Tags", { nargs = "?" }, bind_query(fzf.tags))

  -- neovim providers
  -- (some commands are provided by telescope because it's often better with telescope)
  --    :Commands, :Maps, :Highlights
  command("Buffers", { nargs = "?", complete = "buffer" }, bind_query(fzf.buffers)):alias("B")
  vim.keymap.set('n', '<leader>B', '<Cmd>Buffers<CR>')
  command("Colors", { nargs = "?", complete = "color" }, bind_query(fzf.colorschemes))
  command("Help", { nargs = "?", complete = "help" }, bind_query(fzf.help_tags))
  command("Lines", { nargs = "?" }, bind_query(fzf.lines))
  command("BLines", { nargs = "?" }, bind_query(fzf.blines))
  command("BTags", { nargs= "?" }, bind_query(fzf.btags))
  command("Marks", {}, "FzfLua marks")
  command("Jumps", {}, "FzfLua jumps")
  command("Filetypes", {}, "FzfLua filetypes")
  command("CommandHistory", {}, "FzfLua command_history"):alias("CH")
  command("SearchHistory", {}, "FzfLua search_history"):alias("CH")

  -- [[ Insert-mode Keymaps ]]
  -- similar to i_CTRL-X (:help ins-completion)
  vim.cmd [[
    "imap <C-x><C-k>         <Plug?(fzf-lua-complete.complete_dictionary)
    "imap <C-x><C-t>         <Plug?(fzf-lua-complete.complete_thesaurus)
    "imap <C-x><C-i>         <Plug?(fzf-lua-complete.complete_keywords)
    "imap <C-x><C-]>         <Plug?(fzf-lua-complete.complete_tags)
    imap <C-x><C-f>         <Plug>(fzf-lua-complete.complete_file)
    imap <C-x><C-l>         <Plug>(fzf-lua-complete.complete_line)
    imap <C-x><C-b>         <Plug>(fzf-lua-complete.complete_bline)
  ]]

  -- fzf-lua builtin: path, file, line(open windows), bline(buffer-line)
  local imap = function(...) vim.keymap.set('i', ...) end
  for _, t in pairs { "file", "line", "bline" } do
    imap("<Plug>(fzf-lua-complete.complete_" .. t .. ")",
      function() require("fzf-lua.complete")[t]() end, { silent = true })
  end

  -- TODO: Implement advanced ins-completions, in the past we had
  -- <Plug>(fzf-complete-line-allfiles)
  -- <Plug>(fzf-complete-line-import)

  --- (command line, Ex-mode)
  --- Ctrl-R Ctrl-R: Search history and put the selected entry in the command line
  local cmd_fzf
  vim.keymap.set("c", "<C-r><C-r>", function()
    local cmdtype = vim.fn.getcmdtype()
    local cmdline = vim.fn.getcmdline()
    local fzf_provider, fzf_action
    if cmdtype == ":" then
      fzf_provider, fzf_action = fzf.command_history, require("fzf-lua.actions").ex_run
    elseif cmdtype == "/" then
      fzf_provider, fzf_action = fzf.search_history, require("fzf-lua.actions").search
    else
      return
    end

    vim.schedule(function()
      -- display the cmdline again due to aborting
      vim.api.nvim_echo({ { cmdtype, 'Special'}, { cmdline, 'Special'}, { " (fzf completion)", "None" } }, false, {})
      cmd_fzf(fzf_provider, fzf_action, cmdline)
    end)

    -- need to clear and reject the commandline, otherwise initial query is not empty
    -- and the current cmdline input will be unwantedly added to the command history
    return '<C-u><C-c>'
  end, { expr = true, desc = 'Use fzf-lua command_history to complete command line.' })

  --- Or :: to start searching the history
  vim.keymap.set("c", ":", function()
    return (vim.fn.getcmdtype() == ":" and vim.fn.getcmdline() == "") and "<C-r><C-r>" or ":"
  end, { expr = true, remap = true })

  cmd_fzf = function(fzflua_provider, action, init_query)
    fzflua_provider({
      actions = {
        -- Put in the :ex command line or /search, but do not run yet
        ['default'] = action,
      },
      fzf_opts = {
        -- see ibhagwan/fzf-lua#883 for shellescape() behavior
        ['--query'] = vim.fn.shellescape(init_query or ''),
        ['--layout'] = 'default', -- put prompt in the below
        ['--header'] = false, -- no header (nil means using the default header msg)
        ['--margin'] = 0,
        ["--info"] = "default",
      },
      -- TODO: fzf-lua persists this opts table somewhere globally, find out a bug
      winopts = {
        width = 1.0,
        height = math.floor(math.min(30, 0.7 * vim.o.lines)),
        border = 'none',
        on_create = function()
          local winid = vim.api.nvim_get_current_win()
          -- Use a different color
          vim.opt_local.winhighlight:append("Normal:FzfLuaPmenu")
          -- Put the fzf-lua widget below near the command line, similar to wildmenu
          local height = vim.api.nvim_win_get_config(winid).height
          vim.api.nvim_win_set_config(winid, { row = math.max(1, vim.o.lines - height), col = 0, relative = 'editor' })
        end,
      },
    })
  end

  ---[[ Misc. ]]
  _G.fzf = require('fzf-lua')
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end

(RC or {}).fzf = M
return M
