local base = require('user.lsp.lspconfig.base')

vim.lsp.config('yamlls', { root_dir = base.root_dir })
vim.lsp.enable('yamlls')
