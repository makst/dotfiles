local keyopts = { noremap = true, silent = true }
vim.keymap.set({ 'n', 'v', 'o' }, 'H', require('tree-climber').goto_parent, keyopts)
vim.keymap.set({ 'n', 'v', 'o' }, 'L', require('tree-climber').goto_child, keyopts)
vim.keymap.set({ 'n', 'v', 'o' }, 'J', require('tree-climber').goto_next, keyopts)
vim.keymap.set({ 'n', 'v', 'o' }, 'K', require('tree-climber').goto_prev, keyopts)
vim.keymap.set({ 'v', 'o' }, 'in', require('tree-climber').select_node, keyopts)
vim.keymap.set('n', '<leader>k', require('tree-climber').swap_prev, keyopts)
vim.keymap.set('n', '<leader>j', require('tree-climber').swap_next, keyopts)
vim.keymap.set('n', '<leader>hn', require('tree-climber').highlight_node, keyopts)
