-- extends $VIMPLUG/nvim-lspconfig/lsp/lua_ls.lua

local settings = {
  -- See https://github.com/LuaLS/lua-language-server/blob/master/doc/en-us/config.md
  -- See $MASON/packages/lua-language-server/libexec/locale/en-us/setting.lua
  -- See $MASON/packages/lua-language-server/libexec/script/config/template.lua
  Lua = {
    runtime = {
      version = 'LuaJIT',   -- Lua 5.1/LuaJIT
      pathStrict = true,    -- Do not unnecessarily recurse into subdirs of workspace directory
    },
    diagnostics = {
      -- Ignore some false-positive diagnostics for neovim lua config
      disable = { 'redundant-parameter', 'duplicate-set-field', },
    },
    hint = {
      -- https://github.com/LuaLS/lua-language-server/wiki/Settings#hint
      enable = true, -- inlay hints
      paramType = true, -- Show type hints at the parameter of the function.
      paramName = "Literal", -- Show hints of parameter name (literal types only) at the function call.
      arrayIndex = "Auto", -- Show hints only when the table is greater than 3 items, or the table is a mixed table.
      setType = true,  -- Show a hint to display the type being applied at assignment operations.
    },
    completion = { callSnippet = "Disable" },
    workspace = {
      maxPreload = 10000,

      -- Do not prompt "Do you need to configure your work environment as ..."
      checkThirdParty = false,

      -- If running as a single file on root_dir = ./dotfiles,
      -- this will be in duplicate with library paths. Do not scan invalid lua libs
      ignoreDir = { '.*', 'vim/plugged', 'config/nvim', 'nvim/lua', },

      -- Add additional paths for lua packages
      -- TODO: migrate to https://github.com/folke/lazydev.nvim (it's too buggy yet)
      -- See := vim.lsp.get_clients({ name = 'lua_ls' })[1].settings.Lua.workspace.library
      library = (function()
        local library = {}
        library[vim.env.VIMRUNTIME] = true  -- always include $VIMRUNTIME

        -- add support for all the plugins loaded by lazy.nvim
        -- We got duplicates. vim/plugged in ignoreDir didn't work?
        for _, plugin in ipairs(require("lazy").plugins()) do
          if plugin.enabled == nil or plugin.enabled == true then
            library[plugin.dir .. '/lua'] = true
          end
        end

        if vim.fn.has('mac') > 0 then
          -- http://www.hammerspoon.org/Spoons/EmmyLua.html
          -- Add a line `hs.loadSpoon('EmmyLua')` on the top in ~/.hammerspoon/init.lua
          library[vim.fn.expand('$HOME/.hammerspoon/Spoons/EmmyLua.spoon/annotations')] = true
        end

        return library
      end)(),
    },
  },
};

return {
  settings = settings,
  on_init = function(client, _)
    -- Note that server_capabilities config shouldn't be done in on_attach
    -- due to delayed execution (see neovim/nvim-lspconfig#2542)
    if client.server_capabilities then
      client.server_capabilities.documentFormattingProvider = false
    end
  end,
}
