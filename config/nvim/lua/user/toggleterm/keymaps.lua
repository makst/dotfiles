---@diagnostic disable: lowercase-global
---@diagnostic disable-next-line: unused-local
local status, toggleterm = pcall(require, 'toggleterm')
if (not status) then return end

vim.api.nvim_set_keymap('n', '<leader>lg', '<cmd>lua _lazygit_toggle()<CR>', { silent = true, desc = 'Terminal: lazygit, and hide it' })
vim.api.nvim_set_keymap('n', '<leader>tt', '<cmd>lua _testterm_toggle()<CR>', { silent = true, desc = 'Terminal: the test one, and hide it' })
vim.api.nvim_set_keymap('n', '<leader>tm', '<cmd>lua _miscterm_toggle()<CR>', { silent = true, desc = 'Terminal: a spare one, and hide it' })
