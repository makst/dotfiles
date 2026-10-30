local M = {}

M.setup_keymaps = function(bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gc', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gre', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<C-j>', function() vim.diagnostic.jump({ count = 1, float = true }) end, bufopts)
  vim.keymap.set('n', '<C-k>', function() vim.diagnostic.jump({ count = -1, float = true }) end, bufopts)
  vim.keymap.set('n', '<leader>hd', vim.lsp.buf.hover, bufopts)
  -- signature help: ,hs in normal mode; nvim maps CTRL-S in insert mode by default. `L` is treewalker's
  vim.keymap.set('n', '<leader>hs', vim.lsp.buf.signature_help, bufopts)
end

return M;
