-- order of mason->mason-lspconfig->lspconfig is important
-- https://github.com/williamboman/mason-lspconfig.nvim#setup
require('user.lsp.mason')
require('user.lsp.mason-lspconfig')
require('user.lsp.lspconfig')

-- then set up everything else
require('user.lsp.blink')
require('user.lsp.trouble')
