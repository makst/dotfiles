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
