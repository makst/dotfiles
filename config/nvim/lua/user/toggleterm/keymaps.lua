---@diagnostic disable: lowercase-global
---@diagnostic disable-next-line: unused-local
local status, toggleterm = pcall(require, 'toggleterm')
if (not status) then return end

local ch_term = require('user.toggleterm.cheatsheet_term')

vim.api.nvim_set_keymap('n', '<leader>lg', '<cmd>lua _lazygit_toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<leader>lg', '<cmd>lua _lazygit_toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>tt', '<cmd>lua _testterm_toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<leader>tt', '<cmd>lua _testterm_toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>tm', '<cmd>lua _miscterm_toggle()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<leader>tm', '<cmd>lua _miscterm_toggle()<CR>', { noremap = true, silent = true })


vim.keymap.set('n', '<leader>tc', function ()
  ch_term.cht()
end)
