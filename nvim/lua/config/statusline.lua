-- Statusline config: lualine.nvim

if not pcall(require, 'lualine') then
  print("Warning: lualine not available, skipping configuration.")
  return
end

-- From nvim-lualine/lualine.nvim/wiki/Component-snippets
--- @param trunc_width number trunctates component when screen width is less then trunc_width
--- @param trunc_len number truncates component to trunc_len number of chars
--- @param hide_width number hides component when window width is smaller then hide_width
--- @param trunc_right boolean whether to truncate at right (resulting in prefix) or left (resulting in suffix).
--- return function that can format the component accordingly
local function truncate(trunc_width, trunc_len, hide_width, trunc_right)
  return function(str)
    local win_width = vim.fn.winwidth(0)
    if hide_width and win_width < hide_width then return ''
    elseif trunc_width and trunc_len and win_width < trunc_width and #str > trunc_len then
      if not trunc_right then
        return str:sub(1, trunc_len) .. ('...')
      else
        return '...' .. str:sub(#str - trunc_len + 1, #str)
      end
    end
    return str
  end
end

local function using_global_statusline()
  return vim.opt.laststatus:get() == 3
end

local function min_statusline_width(width)
  return function()
    local statusline_width
    if using_global_statusline() then
      -- global statusline: editor width
      statusline_width = vim.opt.columns:get()
    else
      -- local statusline: window width
      statusline_width = vim.fn.winwidth(0)
    end
    return statusline_width > width
  end
end

local function min_window_with(width)
  return function()
    return vim.fn.winwidth(0) > width
  end
end

-- Customize statusline components
-- https://github.com/shadmansaleh/lualine.nvim#changing-components-in-lualine-sections
local custom_components = {
  -- Override 'encoding': Don't display if encoding is UTF-8.
  encoding = function()
    local ret, _ = (vim.bo.fenc or vim.go.enc):gsub("^utf%-8$", "")  -- Note: '-' is a magic character
    return ret
  end,
  -- fileformat: Don't display if &ff is unix.
  fileformat = function()
    local ret, _ = vim.bo.fileformat:gsub("^unix$", "")
    return ret
  end,
  -- asyncrun & neomake job status
  asyncrun_status = function()
    return table.concat(vim.tbl_values(vim.tbl_map(function(job)
      if job.status == 'running' then return '⏳' end
      return (job.status == 'success' and '✅' or '❌')
    end, vim.g.asyncrun_job_status or {})))
  end,
  neomake_status = function()
    return table.concat(vim.tbl_values(vim.tbl_map(function(job)
      if job.exit_code == nil then return '⏳' end
      return (job.exit_code == 0 and '✅' or '❌')
    end, vim.g.neomake_job_status or {})))
  end,
  -- LSP status, with some trim
  lsp_status = function()
    return LspStatus()
  end,
  -- GPS (https://github.com/SmiteshP/nvim-gps)
  treesitter_context = function()
    local ok, gps = pcall(require, "nvim-gps")
    if ok and gps.is_available() then
      return gps.get_location()
    end
    return ''
  end
}
_G.lualine_components = custom_components

-- With neovim 0.8.0+, we can use laststatus = 3 and winbar.
-- Configure winbar here for the time being, re-using lualine components.
use_global_statusline = vim.fn.has('nvim-0.8.0') > 0

require('lualine').setup {
  options = {
    globalstatus = use_global_statusline,

    -- https://github.com/shadmansaleh/lualine.nvim/blob/master/THEMES.md
    theme = 'onedark'
  },
  -- see ~/.dotfiles/vim/plugged/lualine.nvim/lua/lualine/config.lua
  -- see ~/.dotfiles/vim/plugged/lualine.nvim/lua/lualine/components
  sections = {
    lualine_a = {
      { 'mode', cond = min_statusline_width(40) },
    },
    lualine_b = {
      { 'branch', cond = min_statusline_width(120) },
    },
    lualine_c = {
      custom_components.asyncrun_status,
      custom_components.neomake_status,
      { 'filename', path = 1, color = { fg = '#eeeeee' } },
      { custom_components.treesitter_context },
    },
    lualine_x = {
      --{ custom_components.lsp_status, fmt = truncate(120, 20, 60, false) },
      { custom_components.encoding,   color = { fg = '#d70000' } },
      { custom_components.fileformat, color = { fg = '#d70000' } },
      { 'filetype', cond = min_statusline_width(120) },
    },
    lualine_y = { -- excludes 'progress'
      { 'diff', cond = using_global_statusline },
      'diagnostics',
    },
    lualine_z = {
      { 'location', cond = min_statusline_width(90) },
    },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {
      { 'filename', path = 1 }
    },
    lualine_x = {}, -- excludes 'location'
    lualine_y = {},
    lualine_z = {}
  },
}

-- Now configure winbar, if laststatus = 3 is used.
if use_global_statusline then
  -- Define winbar using lualine components (see lualine.config.apply_configuration)
  local winbar_config = {
    sections = {
      lualine_w = {
        { 'vim.fn.winnr()', color = { fg = 'white', bg = '#37b24d' } },
        { 'filename', path = 1, color = { fg = '#c92a2a', bg = '#eeeeee', gui = 'bold' } },
        'diagnostics',
        { custom_components.treesitter_context, fmt = truncate(80, 20, 60, true) },
        function() return ' ' end,
      },
    },
    inactive_sections = {
      lualine_w = {
        { 'vim.fn.winnr()', color = { fg = '#eeeeee' } },
        { 'filename', path = 1 },
        'diagnostics',
        { custom_components.treesitter_context, fmt = truncate(80, 20, 60, true) },
        function() return ' ' end,
      },
    },
    options = {
      -- component_separators = { left = '', right = ''},
      -- Component separators are stripped when background color is specified. Weird, so not using it :(
      component_separators = '',
    },
    tabline = {},
    extensions = {},
    -- For backward compatibility (broken due to new fields since 53aa3d82)
    winbar = {},
    inactive_winbar = {},
  }
  require 'lualine.utils.loader'.load_all(winbar_config)

  -- The custom winbar function.
  -- seealso ~/.vim/plugged/lualine.nvim/lua/lualine.lua, function statusline
  _G.winbarline = function()
    local is_focused = require 'lualine.utils.utils'.is_focused()
    local line = require 'lualine.utils.section'.draw_section(
      winbar_config[is_focused and 'sections' or 'inactive_sections'].lualine_w,
      'c', -- 'w' is undefined, so re-use highlight of lualine_c for lualine_w (winbar)
      is_focused
    )
    return line
  end

  vim.opt.winbar = "%{%v:lua.winbarline()%}"
end
