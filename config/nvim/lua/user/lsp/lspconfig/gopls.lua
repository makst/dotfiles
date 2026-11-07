-- The Go language server. Loaded by lspconfig/init.lua.
local base = require('user.lsp.lspconfig.base')

vim.lsp.config('gopls', { root_dir = base.root_dir })
vim.lsp.enable('gopls')
