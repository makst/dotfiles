-- outline.nvim's setup (a symbol sidebar). Loaded by user/outline/init.lua.
local status, outline = pcall(require, 'outline')
if (not status) then return end

outline.setup {}
