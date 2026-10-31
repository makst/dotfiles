require('user.lsp.lspconfig.config')
local base = require('user.lsp.lspconfig.base')

-- nvim 0.11+ API: vim.lsp.config() merges over the defaults that nvim-lspconfig ships in lsp/*.lua,
-- vim.lsp.enable() starts the server (see the files below). Completion capabilities come from blink.cmp.

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspAttach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then base.on_attach(client, args.buf) end
  end,
})

require('user.lsp.lspconfig.ts_ls')
require('user.lsp.lspconfig.eslint')
require('user.lsp.lspconfig.lua_ls')
require('user.lsp.lspconfig.yamlls')
require('user.lsp.lspconfig.gopls')
