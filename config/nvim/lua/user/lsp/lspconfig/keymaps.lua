local M = {}

M.setup_keymaps = function(bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gc', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gre', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<C-j>', vim.diagnostic.goto_next, bufopts)
  vim.keymap.set('n', '<C-k>', vim.diagnostic.goto_prev, bufopts)
  vim.keymap.set('n', '<leader>hd', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'L', vim.lsp.buf.signature_help, bufopts)
end

return M;
