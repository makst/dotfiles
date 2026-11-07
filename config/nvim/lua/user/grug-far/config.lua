-- grug-far.nvim's setup (search and replace across files). Loaded by user/grug-far/init.lua.
local status, grug_far = pcall(require, 'grug-far')
if (not status) then return end

grug_far.setup({
  engines = {
    ripgrep = {
      -- hidden files too, and case-insensitive unless the search has a capital letter
      extraArgs = '--hidden --glob=!.git/ --smart-case',
    },
  },
})
