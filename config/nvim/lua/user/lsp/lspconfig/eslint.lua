local status, nvim_lsp = pcall(require, 'lspconfig')
if (not status) then return end
local base = require('user.lsp.lspconfig.base')

nvim_lsp.eslint.setup {
  on_attach = base.on_attach,
  capabilities = base.capabilities,
  root_dir = require('lspconfig.util').root_pattern('.git')
}
-- eslint format on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.tsx', '*.ts', '*.jsx', '*.js' },
  command = 'silent! EslintFixAll',
  group = vim.api.nvim_create_augroup('MyAutocmdsJavaScripFormatting', {}),
})

