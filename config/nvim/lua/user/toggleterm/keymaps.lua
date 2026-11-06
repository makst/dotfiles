---@diagnostic disable: lowercase-global
---@diagnostic disable-next-line: unused-local
local status, toggleterm = pcall(require, 'toggleterm')
if (not status) then return {} end

local M = {}

-- in_float(term): the toggle keys inside the floats too, so the same key hides them again; config.lua passes it
-- as their on_open. Local to their buffers, so other terminals (Gradle, logcat) don't hold every `,` waiting
-- for a second key
function M.in_float(term)
  local opts = { buffer = term.bufnr, silent = true }
  vim.keymap.set('t', '<leader>lg', _lazygit_toggle, vim.tbl_extend('force', opts, { desc = 'Terminal: hide lazygit' }))
  vim.keymap.set('t', '<leader>tt', _testterm_toggle, vim.tbl_extend('force', opts, { desc = 'Terminal: hide the test one' }))
  vim.keymap.set('t', '<leader>tm', _miscterm_toggle, vim.tbl_extend('force', opts, { desc = 'Terminal: hide the spare one' }))
end

vim.api.nvim_set_keymap('n', '<leader>lg', '<cmd>lua _lazygit_toggle()<CR>', { silent = true, desc = 'Terminal: lazygit, and hide it' })
vim.api.nvim_set_keymap('n', '<leader>tt', '<cmd>lua _testterm_toggle()<CR>', { silent = true, desc = 'Terminal: the test one, and hide it' })
vim.api.nvim_set_keymap('n', '<leader>tm', '<cmd>lua _miscterm_toggle()<CR>', { silent = true, desc = 'Terminal: a spare one, and hide it' })

return M
