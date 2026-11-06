---@diagnostic disable-next-line: unused-local
local status, outline = pcall(require, 'outline')
if (not status) then return end

vim.keymap.set('n', '<leader>so', '<Cmd>Outline<CR>', { silent = true, desc = 'Outline: the symbols of this file, show / hide' })
