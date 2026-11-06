local M = {}

M.setup_keymaps = function(bufnr)
  -- not gc (comment with a motion) or gr… (gr would wait for a third key)
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action,
    { silent = true, buffer = bufnr, desc = 'LSP: code actions' })
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,
    { silent = true, buffer = bufnr, desc = 'LSP: rename' })
  -- ]d / [d are nvim's defaults, remapped to also open the float. CTRL-J/K move between nvim and tmux panes
  vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end,
    { silent = true, buffer = bufnr, desc = 'LSP: the next diagnostic' })
  vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end,
    { silent = true, buffer = bufnr, desc = 'LSP: the previous diagnostic' })
  vim.keymap.set('n', '<leader>hd', vim.lsp.buf.hover,
    { silent = true, buffer = bufnr, desc = 'LSP: docs of the word under the cursor' })
  -- signature help: ,hs in normal mode; nvim maps CTRL-S in insert mode by default. `L` is treewalker's
  vim.keymap.set('n', '<leader>hs', vim.lsp.buf.signature_help,
    { silent = true, buffer = bufnr, desc = 'LSP: signature of this call' })
end

return M;
