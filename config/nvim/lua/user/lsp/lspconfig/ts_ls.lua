local base = require('user.lsp.lspconfig.base')

vim.lsp.config('ts_ls', {
  root_dir = base.root_dir,
  cmd = { 'typescript-language-server', '--stdio' },
})
vim.lsp.enable('ts_ls')
