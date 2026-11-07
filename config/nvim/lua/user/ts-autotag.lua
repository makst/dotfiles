-- nvim-ts-autotag: closes and renames HTML / JSX tags together. Loaded by config/nvim/init.lua.
local status, autotag = pcall(require, 'nvim-ts-autotag')
if (not status) then return end

autotag.setup({})
