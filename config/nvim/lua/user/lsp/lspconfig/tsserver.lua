local status, nvim_lsp = pcall(require, 'lspconfig')
if (not status) then return end
local base = require('user.lsp.lspconfig.base')

nvim_lsp.tsserver.setup {
  on_attach = base.on_attach,
  -- https://neovim.discourse.group/t/slow-lsp-on-large-ts-monorepo-project-caching/2668/2
  root_dir = require('lspconfig.util').root_pattern('.git'),
  cmd = { 'typescript-language-server', '--stdio' },
  capabilities = base.capabilities,
}
