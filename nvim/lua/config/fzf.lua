------------
-- fzf + lua
------------

-- https://github.com/ibhagwan/fzf-lua, replaces fzf.vim

local M = {}

local function extend(lhs)
  return function(rhs) return vim.tbl_deep_extend("force", lhs, rhs) end
end

local empty_then_nil = function(x) return x ~= "" and x or nil; end
local command_alias = vim.fn.CommandAlias
local command = function(name, opts, rhs)
  vim.api.nvim_create_user_command(name, rhs, opts)
  return {
    alias = function(self, lhs, ...) command_alias(lhs, name, ...); return self; end,
    nmap = function(self, lhs)
      if type(lhs) == 'string' then lhs = { lhs } end
      for _, key in pairs(lhs) do
        vim.keymap.set('n', key, '<cmd>' .. name .. '<CR>', {})
      end
      return self
    end,
  }
end

function M.setup_fzf()
  local defaults = require('fzf-lua.defaults').defaults
  local FZF_VERSION = require("fzf-lua.utils").fzf_version({}) or 0.0  ---@type float
  local GIT_VERSION = require("fzf-lua.utils").git_version() or 0.0  ---@type float

  -- fzf-lua.setup(opts)
  local global_opts = {
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
        -- If &columns < flip_columns, use horizontal preview; otherwise, vertical preview
        flip_columns = 160,
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
  global_opts.autocmds = {
    winopts = { preview = { layout = "vertical", vertical = "down:33%" } },
  }

  global_opts.grep = {
    keymap = {
      fzf = {
        -- ctrl-q: Send all the result shown in the fzf to quickfix
        -- Note: since using the default action, it will instead jump to the result if #entries == 1
        -- Note, this can be VERY slow if #entires is HUGE; to be improved
        ["ctrl-q"] = "select-all+accept",
      }
    },
    winopts = {
      preview = {
        -- Even larger value; use horizontal preview unless the screen is really wide
        -- (usually &columns ≈ 260 on a full-width 16:9 external monitor screen)
        flip_columns = 200,
      }
    },
    -- headers = {}, -- Do not use the default "interactive_header_txt" header, it's misleading
    fzf_opts = {
      ["--info"] = FZF_VERSION >= 0.42 and "inline-right" or nil,
    },
    copen = "horizontal copen", -- see ibhagwan/fzf-lua#712
  }

  do -- git format and actions customization
    local history_cmd = [[ git log --color --pretty=format:'%C(yellow)%h%Creset %C(auto)%d%Creset %s  %Cgreen(%ar) %C(bold blue)<%an>%Creset' ]]
    global_opts.git = {
      commits = {
        cmd = history_cmd,
        actions = {
          ["default"] = function(selected, ...)
            local commit = (selected[1]):match("[^ ]+")
            vim.cmd.GShow(commit)  -- use diffview.nvim: git show ...
          end,
        }
      },
      bcommits = {
        cmd = history_cmd .. "<file>",
        actions = {
          ["default"] = require("fzf-lua.actions").git_buf_vsplit,
        }
      },
    }
  end

  -- insert-mode completion: turn on preview by default
  global_opts.complete_file = {
    previewer = "default",
    winopts = { preview = { hidden = "nohidden" } },
  }

  require('fzf-lua').setup(global_opts)


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
  command_alias("FL", "FzfLua")

  local fzf = require("fzf-lua")
  -- wrap a fzf-lua provider to a neovim user_command function
  -- with the (optional) argument set as the default fzf query.
  local bind_query = function(fzf_provider)
    return function(e)
      fzf_provider({ query = empty_then_nil(vim.trim(e.args)) })
    end
  end

  -- Finder
  command("Files", { nargs = "?", complete = "dir", desc = "FzfLua files" }, function(e)
    fzf.files({ cwd = empty_then_nil(vim.trim(e.args)) })
  end)
  command("History", {}, "FzfLua oldfiles"):alias("H")
    :nmap({"<leader>FH", "<leader>H"})

  --[[ {grep,rg}-like commands ]]
  -- :Grep      => grep with <search>, and then filter & query via fzf
  --               e.g., :Grep def( => search string "def(" literally
  -- :Grep!     => same as :Grep, but use "raw" regex (do not automatically escape)
  --               e.g., :Grep \b(foo|bar)\b => search word either "foo" or "bar"
  -- :LiveGrep  => grep with <as-you-type> (CTRL-G). Uses "regex mode"
  -- fzf-lua grep uses rg internally
  command("Grep", { nargs = "*", bang = true, desc = "FzfLua grep" }, function(e)
    if e.args == "" then  -- no args were given, prompt and ask
      return vim.ui.input({ prompt = "Grep string ❯ ", relative = "editor" }, function(input)
        if input == nil or input == "" then return end
        vim.schedule_wrap(vim.cmd.Grep)(input)
      end)
    end

    local args = vim.trim(e.args:gsub('\n', ''))
    local should_escape = not e.bang  ---@type boolean
    fzf.grep(vim.tbl_extend("error", {
      prompt = ("Rg%s❯ "):format(e.bang and '!' or ''),
      search = args,
      no_esc = not should_escape,
    }, ( -- see core.set_header()
      e.bang and { headers = {}, fzf_opts = { ["--header"] = "foo" } } -- :Grep! (regex)
      or {} -- :Grep, just the use default header
    )))
  end):alias("Rg")
  command("LiveGrep", { nargs = "?", desc = "FzfLua live_grep" }, function(e)
    fzf.live_grep({ search = vim.trim(e.args) })
  end):alias("RG")

  if vim.fn.executable("rg") == 0 then
    local msg = "rg (ripgrep) not found. Try `dotfiles install rg`."
    vim.notify(msg, vim.log.levels.WARN, { title = "config.fzf" })
  end

  -- keymaps (grep): CTRL-g, <leader>rg
  vim.keymap.set('n', '<C-g>', '<cmd>LiveGrep<CR>')
  vim.keymap.set('n', '<leader>rg', function()
    fzf.grep({
      no_esc = true, -- use raw regex, and manual escaping
      search = "\\b(" .. vim.fn.expand("<cword>") .. ")\\b",  --TODO:escape?
    })
  end, { desc = ':Grep with <cword>' })
  vim.keymap.set('x', '<C-g>', '<leader>rg', { remap = true, silent = true,
    desc = ':Grep with visual selection' } )
  vim.keymap.set('x', '<leader>rg', function()
    vim.cmd.norm [["gy]]  -- copy to the "g register
    local selected_text = vim.fn.getreg("g")
    fzf.grep({
      no_esc = true,
      search = "\\b(" .. selected_text .. ")\\b"  -- TODO:escape?
    })
  end, { silent = true, desc = ':Grep with visual selection' } )


  -- Git providers
  command("Commits", {}, "FzfLua git_commits"  -- for the CWD. TODO: Support file arg
    ):nmap("<leader>FG")
  command("BCommits", {}, "FzfLua git_bcommits")  -- for the buffer.
  command("GitStatus", { nargs = 0 }, "FzfLua git_status")
    :alias("GStatus"):alias("GS"):alias("gs")
    :nmap("<leader>gs")
  command("GitFiles", { nargs = "*", bang = true, complete = "dir", desc = "FzfLua git_files" }, function(e)
    e.args = vim.trim(e.args or "")
    if e.args == "?" then  -- GFiles?
      return vim.cmd [[ GitStatus ]]
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    if #e.args > 0 and vim.loop.fs_stat(vim.fn.expand(e.args) or "") == nil then
      return vim.notify("Not found: " .. e.args, vim.log.levels.WARN, { title = "config.fzf" })
    end
    local opts = { cwd = empty_then_nil(e.args) }
    if e.bang then  -- GFiles!: include untracked files as well
      opts.prompt = "GitFiles!❯ "
      opts.cmd = "git ls-files --exclude-standard --cached --modified --others "
      if GIT_VERSION >= 2.31 then
        opts.cmd = opts.cmd .. "--deduplicate "
      end
    end
    -- Note: Unlike junegunn's GitFiles, it no longer accepts CLI flag. Use Lua API instead
    fzf.git_files(opts)
  end):alias("GFiles", { register_cmd = true }):alias("GF")
  command("GitStashes", { nargs = "?" }, function(e)
    local search = vim.trim(e.args or '')
    fzf.git_stash {
      search = search,
      winopts = { preview = { vertical = "down:80%" } }
    }
  end, "FzfLua git_status"):alias("Stashes")

  command("Tags", { nargs = "?" }, bind_query(fzf.tags))

  -- neovim providers
  -- (some commands are provided by telescope because it's often better with telescope)
  --    :Commands, :Maps, :Highlights
  command("Buffers", { nargs = "?", complete = "buffer" }, bind_query(fzf.buffers)):alias("B")
  vim.keymap.set('n', '<leader>B', '<Cmd>Buffers<CR>')
  command("Colors", { nargs = "?", complete = "color" }, bind_query(fzf.colorschemes))
  command("Help", { nargs = "?", complete = "help" }, bind_query(fzf.help_tags)):alias("He")
  command("Lines", { nargs = "?" }, bind_query(fzf.lines))
  command("BLines", { nargs = "?" }, bind_query(fzf.blines))
  command("BTags", { nargs= "?" }, bind_query(fzf.btags)):nmap("<leader>FT")
  command("Marks", {}, "FzfLua marks"):nmap([['']])
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

  -- Shadow the original :FZF command, alias to FzfLua
  command_alias("FZF", "FzfLua")

  -- Workaround vimr bug (previewer crashes): qvacua/vimr#972
  if vim.fn.has('gui_vimr') > 0 then
    vim.env.FZF_LUA_NVIM_BIN = "nvim"
  end

end


function M.setup_custom()
  -- Custom extensions using fzf-lua
  local fzf = require("fzf-lua")
  local defaults = require("fzf-lua.defaults").defaults
  local echom_warning = function(msg)
    vim.cmd.echohl "WarningMsg"
    vim.cmd.echom ([["]] .. vim.fn.escape(msg, [["]]) .. [["]])
    vim.cmd.echohl "NONE"
  end

  local winopts = { preview = { layout = "vertical", vertical = "down:33%" } }

  -- RgDef: python, search class/function definitions
  local RgDef = function(query, path)
    local ft = vim.bo.filetype
    if ft == "" then return vim.notify("Cannot detect filetype.", vim.log.levels.WARN) end
    local rg_lang = ({
      ['python'] = 'py',
    })[ft] or ft

    local patterns = {
      ['python'] = (function()
        -- if the query itself starts with prefix patterns, (e.g. "def foo" or "class bar")
        -- let query itself be the regex pattern. (\v) turns on the regex magic for vimscript match()
        if vim.fn.match(query, [[\v]] .. [[(def|class)]] .. '($|\\s+)') >= 0 then
          return [[^\s*$query\w*]]
        else
          return [[^\s*(def|class) \w*$query\w*]]
        end
      end)(),
      -- Note: this regex is not perfect, there might be some false negatives, but should be good enough...
      ['lua']    = '(' .. [[^\s*function (\w|\.|:)*$query(\w|\.|:)*]] .. '|'   -- function ...query..()
                       .. [[^.*\.\w*$query\w*\s*=\sfunction]] ..               -- M...query = function()
                   ')',
      _default   = [[\w*$query\w*]],
    }
    local pattern = patterns[ft] or patterns._default
    pattern = pattern:gsub('%$(%w+)', { query = query })

    fzf.grep({
      no_esc = true, -- do not escape query, we will use raw regex
      search = pattern,
      query = query,
      rg_opts = ([[ --type "%s" ]]):format(rg_lang) .. defaults.grep.rg_opts,
      prompt = "RgDef❯ ",
      winopts = winopts,
      cwd = path or ".",
    })
  end
  command("RgDef", { nargs = "?", desc = "RgDef (ripgrep python defs)" }, function(e)
    RgDef(vim.trim(e.args))
  end)
  do
    vim.fn.CommandAlias('D', 'RgDef')
    vim.fn.CommandAlias('Def', 'RgDef', { register_cmd = true })

    -- def-this (current cursor or visual selection)
    vim.cmd [[
      nnoremap <leader>def  <Cmd>execute 'Def ' . expand("<cword>")<CR>
      xnoremap <leader>def  "gy:Def <C-R>g<CR>
    ]]
  end

  local RgPath = function(path, query, rg_extra_args)
    -- try to resolve path argument
    path = (function(path)
      path = path or ""
      if path == "^" then path = vim.fn.DetermineProjectRoot("%") or "" end
      if path == "" then path = "." end
      return vim.fn.expand(path or ".") --[[ @as string ]]
    end)(path)

    if vim.fn.isdirectory(path) == 0 then
      return echom_warning("RgPath: invalid directory: " .. path)
    end

    local provider = (query == "" and fzf.live_grep or fzf.grep)
    provider({
      cwd = vim.fn.expand(path),
      search = query or "",
      rg_opts = (rg_extra_args or "") .. " " .. defaults.grep.rg_opts,
      winopts = winopts,
    })
  end

  -- :RgPath <path> [query]
  command("RgPath", { nargs = "+", complete = 'dir' }, function(e)
    local args = vim.fn.split(vim.trim(e.args)) ---@type string[]
    local query = table.concat({ table.unpack(args, 2) }, ' ')  -- args[2:]
     -- TODO: handle consecutives whitespace (it was buggy in the pasttoo)
    RgPath(args[1], query)
  end)
  -- :RgConfig [query] => search ~/.dotfiles, excluding vim plugins
  -- by default excludes all vim plugins, but :RgConfig! includes all the plugged
  command("RgConfig", { nargs = "*", bang = true, desc = "RgPath on ~/.dotfiles" }, function(e)
    local extra_args = (not e.bang) and [[ -g "!plugged" ]] or nil
    RgPath(vim.fn.expand("$HOME/.dotfiles"), vim.trim(e.args), extra_args)
  end):alias("RC")

  -- :RgRuntime [query] => search $VIMRUNTIME
  command("RgRuntime", { nargs = "*", desc = "RgPath on $VIMRUNTIME" }, function(e)
    RgPath(vim.fn.expand("$VIMRUNTIME"), vim.trim(e.args))
  end):alias("RR"):alias("rgrt"):alias("RgRUNTIME", { register_cmd = true })
  -- :RgLua [query] => search $VIMRUNTIME/query
  command("RgLua", { nargs = "*", desc = "RgPath on $VIMRUNTIME/lua" }, function(e)
    RgPath(vim.fn.expand("$VIMRUNTIME/lua"), vim.trim(e.args))
  end):alias("rglua")

  -- :RgPlug <nvim-plugin-name> [query]
  local plugs_cache = nil
  local complete_plugs = function(...)
    if not plugs_cache then
      plugs_cache = require "config.plugins".list_plugs()
      table.sort(plugs_cache)
    end
    return plugs_cache
  end
  command("RgPlug", { nargs = "+", complete = complete_plugs }, function(e)
    local args = vim.fn.split(vim.trim(e.args)) ---@type string[]
    local query = table.concat({ table.unpack(args, 2) }, ' ')  -- args[2:]
    local plugin_name = args[1]
    if plugin_name == "*" then
      plugin_name = ""
    end
    RgPath(vim.fn.expand("$VIMPLUG") .. "/" .. plugin_name, query)
  end):alias("Rgplug"):alias("RP")

  -- Python package search
  local parse_py_spec = function(args) ---@param args string
    local argv = vim.fn.split(vim.trim(args)) ---@type string[]
    local query = table.concat({ table.unpack(argv, 2) }, ' ')  -- args[2:]
    local package_name = argv[1]
    -- resolve package alias from the mapping
    package_name = (vim.g.python_package_alias or {}).package_name or
      (package_name == '*' and "" or package_name)
    local package_path = vim.fn.PythonSitePackagesDir() .. "/" .. package_name
    return { query = query, package_name = package_name, package_path = package_path }
  end
  -- :DefPackage, :DP <python-package> [query]
  command("DefPackage", { nargs = "+", complete = vim.fn.CompletePythonSitePackages }, function(e)
    local q = parse_py_spec(e.args)
    if vim.fn.isdirectory(q.package_path) == 0 then
      return echom_warning("Package not found: " .. q.package_name)
    end
    RgDef(q.query, q.package_path)
  end):alias("DP"):alias("Dpy")

  -- :RgPackage, :rgpy <python-package> [query]
  command("RgPackage", { nargs = "+", complete = vim.fn.CompletePythonSitePackages }, function(e)
    local q = parse_py_spec(e.args)
    if vim.fn.isdirectory(q.package_path) == 0 then
      return echom_warning("Package not found: " .. q.package_name)
    end
    local extra_args = [[ --type "py" ]]
    RgPath(q.package_path, q.query, extra_args)
  end):alias("Rgpy"):alias("rgpy")
end


function M.setup()
  M.setup_fzf()
  M.setup_custom()
end

-- Resourcing support
if RC and RC.should_resource() then
  M.setup()
end

(RC or {}).fzf = M
return M
