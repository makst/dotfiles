local keymaps_module = require('user.lsp.lspconfig.keymaps')
local M = {}

-- turn off inline buffer error messages
vim.diagnostic.config({ virtual_text = false })

-- Set up completion using nvim_cmp with LSP source
M.capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
M.on_attach = function(client, bufnr)
  keymaps_module.setup_keymaps(bufnr)

  -- formatting
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("Format", { clear = true }),
      buffer = bufnr,
      callback = function() vim.lsp.buf.formatting_seq_sync() end
    })
  end
end

return M
