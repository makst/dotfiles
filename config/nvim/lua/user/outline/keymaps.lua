---@diagnostic disable-next-line: unused-local
local status, outline = pcall(require, 'outline')
if (not status) then return end

local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>so', '<Cmd>Outline<CR>', opts)
