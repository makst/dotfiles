local status, saga = pcall(require, "lspsaga")
if (not status) then return end

saga.init_lsp_saga {
  server_filetype_map = {
    typescript = 'typescript'
  }
}

local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<C-j>', '<Cmd>Lspsaga diagnostic_jump_next<CR>', opts)
vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', opts)
vim.keymap.set('n', 'gd', '<Cmd>Lspsaga lsp_finder<CR>', opts)
vim.keymap.set('i', '<C-k>', '<Cmd>Lspsaga signature_help<CR>', opts)
vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>', opts)
vim.keymap.set('n', 'gr', '<Cmd>Lspsaga rename<CR>', opts)


-- Float terminal
-- open lazygit in lspsaga float terminal
vim.keymap.set("n", "<leader>t", "<cmd>Lspsaga open_floaterm<CR>", { silent = true })
vim.keymap.set("n", "<leader>lg", "<cmd>Lspsaga open_floaterm lazygit<CR>", { silent = true })
-- close floaterm
vim.keymap.set("t", "<leader>q", [[<C-\><C-n><cmd>Lspsaga close_floaterm<CR>]], { silent = true })
