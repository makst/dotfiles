local base = require('user.lsp.lspconfig.base')

vim.lsp.config('eslint', { root_dir = base.root_dir })
vim.lsp.enable('eslint')

-- eslint format on save (LspEslintFixAll is defined by the eslint config's on_attach)
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.tsx', '*.ts', '*.jsx', '*.js' },
  command = 'silent! LspEslintFixAll',
  group = vim.api.nvim_create_augroup('MyAutocmdsJavaScripFormatting', {}),
})
