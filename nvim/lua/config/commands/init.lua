-- Custom Lua-based commands

-- require a lua module, but force reload it (RC files can be re-sourced)
function _require(name)
  package.loaded[name] = nil
  return require(name)
end

_require 'config/commands/AutoBuild'
_require 'config/commands/Config'
_require 'config/commands/Makeprg'
_require 'config/commands/Defer'
