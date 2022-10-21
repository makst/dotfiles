local status, trouble = pcall(require, "trouble")
if (not status) then return end

trouble.setup {}

vim.keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>",
  { silent = true, noremap = true }
)

vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>",
  { silent = true, noremap = true }
)

vim.keymap.set("n", "gr", "<cmd>TroubleToggle lsp_references<cr>",
  { silent = true, noremap = true }
)

vim.keymap.set("n", "gd", "<cmd>TroubleToggle lsp_definitions<cr>",
  { silent = true, noremap = true }
)
