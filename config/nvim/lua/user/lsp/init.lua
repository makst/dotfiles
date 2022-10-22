-- order of mason->mason-lspconfig->lspconfig is important
-- https://github.com/williamboman/mason-lspconfig.nvim#setup
require('user.lsp.mason')
require('user.lsp.mason-lspconfig')
require('user.lsp.lspconfig')

-- then set up everything else
require('user.lsp.cmp')
require('user.lsp.lspkind')
require('user.lsp.lspsaga')
require('user.lsp.trouble')
