---@diagnostic disable-next-line: unused-local
local status, nvim_tree = pcall(require, 'nvim-tree')
if (not status) then return end

vim.keymap.set('n', '<leader>e', '<Cmd>NvimTreeToggle<CR>', { silent = true, desc = 'File tree: show / hide' })
vim.keymap.set('n', '<leader>f', '<Cmd>NvimTreeFindFileToggle<CR>', { silent = true, desc = 'File tree: this file in it' })
