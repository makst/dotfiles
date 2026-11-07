-- nvim-autopairs: closes brackets and quotes as you type. Loaded by config/nvim/init.lua.
local status, autopairs = pcall(require, 'nvim-autopairs')
if (not status) then return end

autopairs.setup({
  disable_filetype = { 'vim' },
})
