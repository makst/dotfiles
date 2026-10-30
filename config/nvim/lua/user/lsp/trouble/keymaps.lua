local opts = { noremap = true, silent = true }
-- trouble.nvim v3 syntax (`:TroubleToggle <mode>` was removed)
vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', opts)
vim.keymap.set('n', '<leader>xw', '<cmd>Trouble diagnostics toggle<cr>', opts) -- v3 diagnostics are workspace-wide
vim.keymap.set('n', '<leader>xd', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', opts)
vim.keymap.set('n', 'gr', '<cmd>Trouble lsp_references toggle<cr>', opts)
vim.keymap.set('n', 'gd', '<cmd>Trouble lsp_definitions toggle<cr>', opts)
