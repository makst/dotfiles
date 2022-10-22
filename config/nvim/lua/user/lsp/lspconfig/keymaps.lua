local M = {}

M.setup_keymaps = function(bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gc', vim.lsp.buf.code_action, bufopts)
end

return M;
