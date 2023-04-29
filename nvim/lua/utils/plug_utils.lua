-- Legacy vimscript config support. see vimrc:PlugConfig
-- can be used as { init = PlugConfig } or { init = PlugConfig['plugin_name'] }
local PlugConfig = setmetatable({}, {
  __index = function(_, name)
    return function()
      if vim.g.PlugConfig[name] == nil then
        return error(string.format("There is no PlugConfig for `%s`", name))
      end
      vim.cmd(string.format('call g:PlugConfig["%s"]()', name))
    end
  end,
  __call = function(self, lazy_plugin)
    return self[lazy_plugin.name]()
  end,
})

-- Plug, a syntactic sugar for LazyPlugin specs.
local Plug = function(name)
  return setmetatable({name}, {__call = function(self, opt)
    return vim.tbl_extend("error", self, opt)
  end})
end

-- :UpdateRemotePlugins build hook for (python) rplugins
local UpdateRemotePlugins = function(lazy_plugin)
  -- The generated rplugin manifest needs to be sourced
  -- so that the plugin is ready to use right after fresh installation.
  -- :UpdateRemotePlugins should be called only once after all rplugins are loaded,
  -- so we defer its execution. See configs/plugin.lua where it's actually executed.
  if lazy_plugin then
    vim.g._need_UpdateRemotePlugins = 1
  else
    -- apply and source UpdateRemotePlugins after all rplugins are loaded
    if vim.g._need_UpdateRemotePlugins then
      vim.cmd [[
        :UpdateRemotePlugins
        :source $HOME/.local/share/nvim/rplugin.vim
        :unlet! g:_need_UpdateRemotePlugins
      ]]
    end
  end
end

-- exports
return {
  Plug = Plug,
  PlugConfig = PlugConfig,
  UpdateRemotePlugins = UpdateRemotePlugins,
}
