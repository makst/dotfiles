local status, grug_far = pcall(require, 'grug-far')
if (not status) then return end

-- ,sr: search and replace across files; in visual mode the selection is the search
vim.keymap.set({ 'n', 'x' }, '<leader>sr', function() grug_far.open() end)
