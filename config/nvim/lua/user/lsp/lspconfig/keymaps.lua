local M = {}

M.setup_keymaps = function(bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  -- not gc (comment with a motion) or gr… (gr would wait for a third key)
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  -- ]d / [d are nvim's defaults, remapped to also open the float. CTRL-J/K move between nvim and tmux panes
  vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, bufopts)
  vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, bufopts)
  vim.keymap.set('n', '<leader>hd', vim.lsp.buf.hover, bufopts)
  -- signature help: ,hs in normal mode; nvim maps CTRL-S in insert mode by default. `L` is treewalker's
  vim.keymap.set('n', '<leader>hs', vim.lsp.buf.signature_help, bufopts)
end

return M;
