local status, nvim_lsp = pcall(require, 'lspconfig')
if (not status) then return end
local base = require('user.lsp.lspconfig.base')

nvim_lsp.yamlls.setup {
  on_attach = base.on_attach,
  -- https://neovim.discourse.group/t/slow-lsp-on-large-ts-monorepo-project-caching/2668/2
  root_dir = require('lspconfig.util').root_pattern('.git'),
  capabilities = base.capabilities,
}
