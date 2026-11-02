-- The language servers themselves come from the Brewfile, so they are on PATH; lspconfig only configures them.
require('user.lsp.lspconfig')

-- then set up everything else
require('user.lsp.blink')
require('user.lsp.trouble')
