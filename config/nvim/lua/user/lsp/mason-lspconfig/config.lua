---@diagnostic disable-next-line: unused-local
local status_ok, _mason_lspconfig = pcall(require, 'mason-lspconfig')
if not status_ok then return end

local mason_lspconfig = require('mason-lspconfig')

mason_lspconfig.setup({
  ensure_installed = {
    'lua_ls',
    'ts_ls',
    'eslint',
    'yamlls',
    'gopls'
  },
  -- servers are set up explicitly in user.lsp.lspconfig; the default (on) enables each
  -- installed server a second time, giving two clients per buffer
  automatic_enable = false,
})
