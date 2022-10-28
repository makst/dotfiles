local status, nvim_lsp = pcall(require, 'lspconfig')
if (not status) then return end
local base = require('user.lsp.lspconfig.base')

nvim_lsp.sumneko_lua.setup {
  on_attach = base.on_attach,
  capabilities = base.capabilities,
  settings = {
    Lua = {
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { 'vim' },
      },

      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false
      },
    },
  },
}

