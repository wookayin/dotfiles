-- neovim plugins managed by lazy.nvim
-- Plugins specs are located at: ~/.config/nvim/lua/plugins/

local M = {}

-- Pin at lazy < v10, because it breaks cond since fbb0bea2
local LAZY_VERSION = 'v9.25.1'  -- or 'stable'

local PLUGIN_SPEC = {
  { 'folke/lazy.nvim', tag = LAZY_VERSION },
  { import = "plugins.basic" },
  { import = "plugins.appearance" },
  { import = "plugins.ui" },
  { import = "plugins.keymap" },
  { import = "plugins.git" },
  { import = "plugins.ide" },
  { import = "plugins.treesitter" },
  { import = "plugins.utilities" },
}
if pcall(require, "plugins.local") then
  -- see ~/.config/nvim/lua/plugins/local.lua
  table.insert(PLUGIN_SPEC, { import = "plugins.local" })
end

-- $VIMPLUG
-- vim.env.VIMPLUG = vim.fn.stdpath("data") .. "/lazy"
vim.env.VIMPLUG = vim.fn.expand('$HOME/.vim/plugged')

-- Bootstrap lazy.nvim plugin manager
-- https://github.com/folke/lazy.nvim
local lazypath = vim.env.VIMPLUG .. "/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=" .. LAZY_VERSION,
    lazypath,
  })
  if vim.v.shell_error > 0 then
    vim.api.nvim_err_writeln("Downloading lazy.nvim failed. Please check your internet connection.")
    return false
  end
end
vim.opt.rtp:prepend(lazypath)

-- Disable lazy clean by monkey-patching. (see folke/lazy.nvim#762)
require("lazy.manage").clean = function(opts)
  opts = opts or {}
  print("[lazy.nvim] Clean operation is disabled. args = " .. ((opts.plugin or {}).dir or '') .. '\n')
  return require("lazy.manage").run({ pipeline = {} })
end
require("lazy.manage.task.fs").clean.run = function(self)
  ---@diagnostic disable-next-line: undefined-field
  local plugin_name = (self.plugin or {}).name or '(unknown)'
  print("[lazy.nvim] Clean operation is disabled. (lazy.manage.task.fs) plugin = " .. plugin_name .. '\n')
  local inform_user = function()
    local msg = ("[lazy.nvim] Please check and remove `%s/%s.cloning` manually.\n"):format(vim.env.VIMPLUG, plugin_name)
    vim.notify(msg, vim.log.levels.ERROR, { title = 'config/plugins.lua', timeout = 10000, markdown = true })
  end
  vim.api.nvim_create_autocmd('VimEnter', { pattern = '*', callback = inform_user })
  inform_user()  -- for headless execution
end

-- Monkey-patch: Normalize git origin, avoid unnecessary re-cloning on update
---@param repo string path to the git repository
require("lazy.manage.git").get_origin = function(repo)
  local origin = require("lazy.manage.git").get_config(repo)["remote.origin.url"]
  origin = string.gsub(origin, 'git@github.com:', 'https://github.com/')
  origin = string.gsub(origin, 'https://git::@github.com/', 'https://github.com/')
  return origin
end

-- workaround for neovim/neovim#27413
-- vim.fs must be loaded before vim.loader.enable()
require("vim.fs")

-- Setup and load plugins. All plugins will be source HERE!
-- https://github.com/folke/lazy.nvim#%EF%B8%8F-configuration
-- @see $VIMPLUG/lazy.nvim/lua/lazy/core/config.lua
require("lazy").setup(PLUGIN_SPEC, {
  root = vim.env.VIMPLUG,
  defaults = {
    -- Plugins will be loaded as soon as lazy.setup()
    lazy = false,
  },
  install = {
    missing = true,
    colorscheme = {"xoria256-wook"},
  },
  ui = {
    wrap = true,
    border = 'double',
    icons = {  -- Nerd-font v3 (https://www.nerdfonts.com/cheat-sheet)
      func = "󰊕",
      list = { "●", "➜", "", "-" },
    }
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "netrwPlugin",
      },
    },
  },
  change_detection = {
    notify = true,
  },
})

-- Close auto-install window
vim.cmd [[
  if &filetype == 'lazy' | q | endif
]]

-- Add rplugins support on startup; see utils/plug_utils.lua
require("utils.plug_utils").UpdateRemotePlugins()

-- Additional lazy-load events: 'func' (until it's officially supported)
local Lazy_FuncUndefined = vim.api.nvim_create_augroup('Lazy_FuncUndefined', { clear = true })
vim.tbl_map(function(p)   ---@type LazyPluginSpec
  if p.lazy and p.func then
    vim.api.nvim_create_autocmd('FuncUndefined', {
      pattern = p.func,
      group = Lazy_FuncUndefined,
      once = true,
      callback = function(ev)
        -- the actual function that was required and triggered the plugin.
        local reason = { func = ev.match }
        require("lazy.core.loader").load(p.name, reason, { force = true })
      end,
      desc = string.format("Lazy plugin: %s, func: %s", p.name, (function()
        if type(p.func) == 'string' then return p.func
        else return "{ " .. table.concat(p.func, ", ") .. " }"
        end
      end)()),
    })
  end
end, require("lazy").plugins())


-- remap keymaps and configure lazy window
require("lazy.view.config").keys.profile_filter = "<C-g>"
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lazy",
  callback = function(args)
    local buf = args.buf
    vim.defer_fn(function()
      -- Ctrl+C: to quit the window (only if it's floating)
      vim.keymap.set("n", "<C-c>", function()
        local is_float = vim.api.nvim_win_get_config(0).relative ~= ""
        return is_float and "q" or ""
      end, { buffer = true, remap = true, expr = true })

      -- Highlights
      vim.cmd [[
        hi! LazyProp guibg=NONE
        hi def link LazyReasonFunc  Function
      ]]

      -- make goto-file (gf, ]f) work, but open in a new tab
      vim.opt_local.path:append(vim.env.VIMPLUG)
      vim.keymap.set('n', 'gf', '<cmd>wincmd gf<CR>', { remap = false, buffer = true })
      vim.keymap.set('n', ']f', 'gf', { remap = true, buffer = true })

      -- folding support
      vim.cmd [[ setlocal sw=2 foldmethod=expr foldexpr=v:lua.lazy_foldexpr() ]]
      pcall(function()
        -- UFO somehow doesn't get attached automatically, so manually enable folding
        require("ufo").attach(buf)
      end)
    end, 0)
  end,
})

-- foldexpr for Lazy
function _G.lazy_foldexpr(lnum)
  lnum = lnum or vim.v.lnum
  local l = vim.fn.getline(lnum)
  if l:match("^%s*$") then
    return 0
  end
  local indent_next = vim.fn.indent(lnum + 1)
  local indent_this = vim.fn.indent(lnum)
  local sw = 2  -- tab size
  if indent_next < indent_this then
    return '<' .. (indent_this / sw - 1)
  elseif indent_next > indent_this then
    return '>' .. (indent_next / sw - 1)
  else
    return indent_this / sw - 1
  end
end

-- :PlugWhere -- quickly locate and find plugin defs
-- TODO: Use lazy API to retrieve full plugin spec instead of grep.
vim.api.nvim_create_user_command('PlugWhere', function(opts)
  local entry_maker = require('telescope.make_entry').gen_from_vimgrep({ })
  require('telescope.builtin').grep_string({
    search_dirs = { '~/.config/nvim/lua/plugins' },
    only_sort_text = true,
    use_regex = true,
    search = 'Plug \'.+\'',
    default_text = opts.args,
    entry_maker = function(line)
      local e = entry_maker(line)
      e.ordinal = e.text
      e.display = function()
        local plug_id = e.text:match([['(.-)']])  -- extract string within '' (shorturl)
        local display = plug_id .. ('   ') .. string.format('[%s]', e.filename:match(".+/(.*)$") )
        return display, {
          { {plug_id:find('/'), #plug_id}, 'Identifier' },
          { {#plug_id + 1, #display}, 'Comment' },
        }
      end
      e.col = e.col + 6  -- a hack to make the jump location (column) located in the shorturl
      return e
    end,
    layout_config = {
      preview_cutoff = 80,
      preview_width = 0.5,
    },
  })
end, {
  nargs = '?', desc = 'PlugWhere: find lazy plugin declaration.',
  complete = function()
    local names = M.list_plugs(); table.sort(names); return names
  end
})
pcall(vim.fn.CommandAlias, 'PW', 'PlugWhere', false)

-- Some command alias for :Lazy
pcall(function()
  local register_cmd = true
  vim.fn.CommandAlias('LazyProfile', 'Lazy profile', register_cmd)
end)

--- list_plugs: Get all the registered plugins (including non-loaded ones)
---@return string[]
function M.list_plugs()
  return vim.tbl_keys(require("lazy.core.config").plugins)
end

--- Get a LazyPlugin table by its name (exact).
---@param name string
---@return LazyPlugin|nil
function M.get_plugin(name)
  return require("lazy.core.config").plugins[name]
end

-- load: immediately load (lazy) plugins synchronously
---@return LazyPlugin?
function M.load(names)
  require("lazy.core.loader").load(names, {}, { force = true })
end

_G.lazy = require("lazy");
return M
