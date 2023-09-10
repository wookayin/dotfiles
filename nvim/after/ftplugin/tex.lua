-- ftplugin: tex.lua
-- See also ftplugin/tex.vim which needs migration to lua

-- Configure :Build
require('config.tex').setup_compiler_commands()
