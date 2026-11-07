-- gitsigns.nvim: changed lines in the sign column. Loaded by user/git/init.lua.
local status, gitsigns = pcall(require, 'gitsigns')
if (not status) then return end

gitsigns.setup {}
