-- trouble.nvim's setup (lists of diagnostics). Loaded by user/lsp/trouble/init.lua.
local status, trouble = pcall(require, 'trouble')
if (not status) then return end

trouble.setup {}
