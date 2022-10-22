---@diagnostic disable-next-line: unused-local
local status, nvim_tree = pcall(require, "nvim-tree")
if (not status) then return end

local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', '<Cmd>NvimTreeToggle<CR>', opts)
vim.keymap.set('n', '<leader>f', '<Cmd>NvimTreeFindFileToggle<CR>', opts)
