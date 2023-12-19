local M = {}

-- Legacy vimscript config support. see vimrc:PlugConfig
-- can be used as { init = PlugConfig } or { init = PlugConfig['plugin_name'] }
---@type fun(plugin: LazyPlugin)
---@diagnostic disable-next-line: assign-type-mismatch
M.PlugConfig = setmetatable({}, {
  ---@param name string
  __index = function(_, name)
    return function()
      if vim.g.PlugConfig[name] == nil then
        return error(string.format("There is no PlugConfig for `%s`", name))
      end
      vim.cmd(string.format('call g:PlugConfig["%s"]()', name))
    end
  end,
  ---@param lazy_plugin LazyPlugin
  __call = function(self, lazy_plugin)
    return self[lazy_plugin.name]()
  end,
})


---@alias LazyPluginSpecFunctor fun(opt: LazyPluginSpecExt): LazyPluginSpecExt

---@class LazyPluginSpecExt:LazyPluginSpec
---@field dependencies? string|string[]|LazyPluginSpec[]|LazyPluginSpecFunctor[]

-- Plug, a syntactic sugar for LazyPlugin specs.
---@param name string
---@return LazyPluginSpecFunctor
M.Plug = function(name)
  ---@diagnostic disable-next-line: return-type-mismatch
  return setmetatable({name}, {
    __call = function(self, opt)
      return vim.tbl_extend("error", self, opt)
    end,
  })
end

-- :UpdateRemotePlugins build hook for (python) rplugins
M.UpdateRemotePlugins = function(lazy_plugin, opts)
  -- The generated rplugin manifest needs to be sourced
  -- so that the plugin is ready to use right after fresh installation.
  -- :UpdateRemotePlugins should be called only once after all rplugins are loaded,
  -- so we defer its execution. See configs/plugin.lua where it's actually executed.
  if lazy_plugin then
    vim.g._need_UpdateRemotePlugins = 1
  else
    -- apply and source UpdateRemotePlugins after all rplugins are loaded
    if vim.g._need_UpdateRemotePlugins or (opts or {}).force then
      -- activate all the plugins with UpdateRemotePlugins that are lazy-loaded
      local to_load = {}
      for name, spec in pairs(require("lazy.core.config").plugins) do
        if spec.build == M.UpdateRemotePlugins then
          to_load[#to_load + 1] = name
        end
      end
      vim.notify("Force-loading plugins: " .. vim.inspect(to_load))
      require("lazy.core.loader").load(to_load, { cmd = "UpdateRemotePlugins" })

      vim.cmd [[
        :UpdateRemotePlugins
        try
          :source $HOME/.local/share/nvim/rplugin.vim
        catch  " ignore already-registered errors; on next startup it'll be fine.
        endtry
        :unlet! g:_need_UpdateRemotePlugins
      ]]
    end
  end
end

return M
