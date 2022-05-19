-- Statusline config: lualine.nvim


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
local function min_window_width(width)
  return function() return vim.fn.winwidth(0) > width end
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
  -- neomake job status
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

require('lualine').setup {
  options = {
    -- https://github.com/shadmansaleh/lualine.nvim/blob/master/THEMES.md
    theme = 'onedark'
  },
  -- see ~/.dotfiles/vim/plugged/lualine.nvim/lua/lualine/config.lua
  -- see ~/.dotfiles/vim/plugged/lualine.nvim/lua/lualine/components
  sections = {
    lualine_a = {
      { 'mode', cond = min_window_width(40) },
    },
    lualine_b = {
      { 'branch', cond = min_window_width(120) },
    },
    lualine_c = {
      custom_components.neomake_status,
      { 'filename', path = 1, color = { fg = '#eeeeee' } },
      custom_components.treesitter_context,
    },
    lualine_x = {
      --{ custom_components.lsp_status, fmt = truncate(120, 20, 60, false) },
      { custom_components.encoding,   color = { fg = '#d70000' } },
      { custom_components.fileformat, color = { fg = '#d70000' } },
      { 'filetype', cond = min_window_width(120) },
    },
    lualine_y = {},  -- excludes 'progress'
    lualine_z = {
      { 'location', cond = min_window_width(90) },
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
