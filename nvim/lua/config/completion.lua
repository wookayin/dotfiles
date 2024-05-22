-- auto-completion (cmp) config

local M = {}

---------------------------------
--- nvim-cmp: completion support
---------------------------------
-- https://github.com/hrsh7th/nvim-cmp#recommended-configuration
-- $VIMPLUG/nvim-cmp/lua/cmp/config/default.lua

local has_words_before = function()
  if vim.bo[0].buftype == 'prompt' then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

local truncate = function(text, max_width)
  if #text > max_width then
    return string.sub(text, 1, max_width) .. "…"
  else
    return text
  end
end


M.setup_cmp = function()
  local cmp = require('cmp')
  local SelectBehavior = require('cmp.types.cmp').SelectBehavior
  local ContextReason = require('cmp.types.cmp').ContextReason

  vim.o.completeopt = "menu,menuone,noselect"

  -- See $VIMPLUG/nvim-cmp/lua/cmp/config/default.lua
  ---@see cmp.ConfigSchema
  local cmp_config = {
    ---@see cmp.SnippetConfig
    snippet = {
      ---@param args cmp.SnippetExpansionParams
      expand = function(args)
        local snippet_expand = (
          vim.snippet ~= nil and vim.snippet.expand  -- nvim 0.10+
          or vim.fn["UltiSnips#Anon"]
        )
        snippet_expand(args.body)
      end,
    },
    ---@see cmp.WindowConfig
    window = {
      documentation = {
        border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
      },
      completion = {
        -- Use border for the completion window.
        border = { '┌', '─', '┐', '│', '┘', '─', '└', '│' },

        -- Due to the border, move left the completion window by 1 column
        -- so that text in the editor and on completion item can be aligned.
        col_offset = -1,

        winhighlight = 'Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None',
      }
    },
    ---@type table<string, cmp.Mapping>
    mapping = {
      -- See $VIMPLUG/nvim-cmp/lua/cmp/config/mapping.lua
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete({ reason = ContextReason.Manual }),
      ['<C-y>'] = cmp.config.disable,
      ['<C-e>'] = cmp.mapping.close(),
      ['<Down>'] = cmp.mapping.select_next_item({ behavior = SelectBehavior.Select }),
      ['<Up>'] = cmp.mapping.select_prev_item({ behavior = SelectBehavior.Select }),
      ['<C-n>'] = cmp.mapping.select_next_item({ behavior = SelectBehavior.Insert }),
      ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = SelectBehavior.Insert }),
      ['<CR>'] = cmp.mapping.confirm({ select = false }),
      ['<Tab>'] = { -- see GH-880, GH-897
        i = function(fallback) -- see GH-231, GH-286
          if cmp.visible() then cmp.select_next_item()
          elseif has_words_before() then cmp.complete()
          else fallback() end
        end,
      },
      ['<S-Tab>'] = {
        i = function(fallback)
          if cmp.visible() then cmp.select_prev_item()
          else fallback() end
        end,
      },
    },
    ---@see cmp.FormattingConfig
    formatting = {
      format = function(...)
        return M.format(...)
      end,
    },
    ---@type cmp.SourceConfig[]
    sources = {
      -- Note: make sure you have proper plugins specified in plugins.vim
      -- https://github.com/topics/nvim-cmp
      { name = 'nvim_lsp', priority = 100 },
      { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
      { name = 'path', priority = 30 },
      { name = 'omni', priority = 20 },
      { name = 'buffer', priority = 10 },
    },
    ---@see cmp.SortingConfig
    sorting = {
      -- see $VIMPLUG/nvim-cmp/lua/cmp/config/compare.lua
      comparators = {
        cmp.config.compare.offset,
        cmp.config.compare.exact,
        cmp.config.compare.score,
        function(...) return M.comparators.prioritize_argument(...) end,
        function(...) return M.comparators.deprioritize_underscore(...) end,
        cmp.config.compare.recently_used,
        cmp.config.compare.kind,
        cmp.config.compare.sort_text,
        cmp.config.compare.length,
        cmp.config.compare.order,
      },
    },
  }

  ---@diagnostic disable-next-line: missing-fields
  cmp.setup(cmp_config)

  -- filetype-specific sources
  require("cmp_zsh").setup { filetypes = { "bash", "zsh" } }
  ---@diagnostic disable-next-line: missing-fields
  cmp.setup.filetype({'sh', 'zsh', 'bash'}, {
    sources = cmp.config.sources({
      { name = 'zsh', priorty = 100 },
      { name = 'nvim_lsp', priority = 50 },
      { name = 'ultisnips', keyword_length = 2, priority = 50 },  -- workaround '.' trigger
      { name = 'path', priority = 30, },
      { name = 'buffer', priority = 10 },
    }),
  })

  -- Highlights
  require('utils.rc_utils').RegisterHighlights(M.apply_highlight)

  do  -- set pumheight: limit popup menu height
    function _reset_pumheight()
      vim.o.pumheight = math.max(20, math.floor(vim.o.lines * 0.5))
    end
    vim.api.nvim_create_autocmd('VimResized', {
      pattern = '*',
      group = vim.api.nvim_create_augroup('lsp_cmp_on_resized_pumheight', { clear = true }),
      callback = function() _reset_pumheight() end,
    })
    _reset_pumheight()
  end
end


---@param entry cmp.Entry
---@param vim_item vim.CompletedItem
function M.format(entry, vim_item)
  -- Truncate the item if it is too long
  vim_item.abbr = truncate(vim_item.abbr, 80)
  -- fancy icons and a name of kind
  pcall(function()  -- protect the call against potential API breakage (lspkind GH-45).
    local lspkind = require("lspkind")
    vim_item.kind_symbol = (lspkind.symbolic or lspkind.get_symbol)(vim_item.kind)
    vim_item.kind = " " .. vim_item.kind_symbol .. " " .. vim_item.kind
  end)

  -- The 'menu' section: source, detail information (lsp, snippet), etc.
  -- set a name for each source (see the sources section below)
  vim_item.menu = ({
    buffer        = "Buffer",
    nvim_lsp      = "LSP",
    ultisnips     = "",
    nvim_lua      = "Lua",
    latex_symbols = "Latex",
  })[entry.source.name] or string.format("%s", entry.source.name)

  -- highlight groups for item.menu
  vim_item.menu_hl_group = ({
    buffer = "CmpItemMenuBuffer",
    nvim_lsp = "CmpItemMenuLSP",
    path = "CmpItemMenuPath",
    ultisnips = "CmpItemMenuSnippet",
  })[entry.source.name]  -- default is CmpItemMenu

  -- detail information (optional)
  local cmp_item = entry:get_completion_item()  --- @type lsp.CompletionItem

  if entry.source.name == 'nvim_lsp' then
    -- Display which LSP servers this item came from.
    local lspserver_name = nil
    pcall(function()
      lspserver_name = entry.source.source.client.name
      vim_item.menu = lspserver_name
    end)

    -- Some language servers provide details, e.g. type information.
    -- The details info hide the name of lsp server, but mostly we'll have one LSP
    -- per filetype, and we use special highlights so it's OK to hide it..
    local detail_txt = (function()
      if not cmp_item.detail then return nil end

      if cmp_item.detail == "Auto-import" then
        local label = (cmp_item.labelDetails or {}).description
        if not label or label == "" then return nil end
        local logo = ({
          pyright = "",
          basedpyright = "",
        })[lspserver_name] or "󰋺"
        return logo .. " " .. truncate(label, 20)
      else
        return truncate(cmp_item.detail, 50)
      end
    end)()
    if detail_txt then
      vim_item.menu = detail_txt
      vim_item.menu_hl_group = 'CmpItemMenuDetail'
    end

  elseif entry.source.name == 'zsh' then
    -- cmp-zsh: Display documentation for cmdline flag ('' denotes zsh)
    ---@diagnostic disable-next-line: undefined-field
    local detail = tostring(cmp_item.documentation)
    if detail then
      vim_item.menu = detail
      vim_item.menu_hl_group = 'CmpItemMenuZsh'
      vim_item.kind = '  ' .. 'zsh'
    end

  elseif entry.source.name == 'ultisnips' then
    ---@diagnostic disable-next-line: undefined-field
    local description = (cmp_item.snippet or {}).description
    if description then
      vim_item.menu = truncate(description, 40)
    end
  end

  -- Add a little bit more padding
  vim_item.menu = " " .. vim_item.menu
  return vim_item
end

-- Custom sorting/ranking for completion items.
M.comparators = {
  ---Deprioritize items starting with underscores (private or protected)
  ---@type fun(lhs: cmp.Entry, rhs: cmp.Entry): boolean|nil
  deprioritize_underscore = function(lhs, rhs)
    local l = (lhs.completion_item.label:find "^_+") and 1 or 0
    local r = (rhs.completion_item.label:find "^_+") and 1 or 0
    if l ~= r then return l < r end
  end,

  ---Prioritize items that ends with "= ..." (usually for argument completion).
  ---@type fun(lhs: cmp.Entry, rhs: cmp.Entry): boolean|nil
  prioritize_argument = function(lhs, rhs)
    local l = (lhs.completion_item.label:find "=$") and 1 or 0
    local r = (rhs.completion_item.label:find "=$") and 1 or 0
    if l ~= r then return l > r end
  end,
}

-- Highlights with bordered completion window (GH-224, GH-472)
function M.apply_highlight()
  vim.cmd [[
    " Dark background, and white-ish foreground
    highlight! CmpPmenu         guibg=#242a30
    highlight! CmpPmenuBorder   guibg=#242a30
    highlight! CmpItemAbbr      guifg=#eeeeee
    highlight! CmpItemMenuDefault   guifg=white
    " gray
    highlight! CmpItemAbbrDeprecated    guibg=NONE gui=strikethrough guifg=#808080
    " fuzzy matching
    highlight! CmpItemAbbrMatch         guibg=NONE guifg=#f03e3e gui=bold
    highlight! CmpItemAbbrMatchFuzzy    guibg=NONE guifg=#fd7e14 gui=bold

    " Item Kinds. defaults to CmpItemKind (#cc5de8)
    " see $VIMPLUG/nvim-cmp/lua/cmp/types/lsp.lua
    " {✅Class, ✅Module, ✅Interface, Struct, ✅Function, ✅Method, ✅Constructor,
    "  ✅Variable, ✅Property, Field, ✅Unit, Value, Enum, EnumMember, Event,
    "  ✅Keyword, Color, File, Reference, Folder, Constant, Operator, TypeParameter,
    "  ✅Snippet, ✅Text}

    " see SemshiGlobal
    highlight!      CmpItemKindModule        guibg=NONE guifg=#FF7F50
    highlight!      CmpItemKindClass         guibg=NONE guifg=#FFAF00
    highlight! link CmpItemKindStruct        CmpItemKindClass
    highlight!      CmpItemKindVariable      guibg=NONE guifg=#9CDCFE
    highlight!      CmpItemKindProperty      guibg=NONE guifg=#9CDCFE
    highlight!      CmpItemKindFunction      guibg=NONE guifg=#C586C0
    highlight! link CmpItemKindConstructor   CmpItemKindFunction
    highlight! link CmpItemKindMethod        CmpItemKindFunction
    highlight!      CmpItemKindKeyword       guibg=NONE guifg=#FF5FFF
    highlight!      CmpItemKindText          guibg=NONE guifg=#D4D4D4
    highlight!      CmpItemKindUnit          guibg=NONE guifg=#D4D4D4
    highlight!      CmpItemKindConstant      guibg=NONE guifg=#409F31
    highlight!      CmpItemKindSnippet       guibg=NONE guifg=#E3E300
  ]]
end

return M
