local keymaps_module = require('user.lsp.lspconfig.keymaps')
local M = {}

-- Set up completion using nvim_cmp with LSP source
M.capabilities = require('cmp_nvim_lsp').default_capabilities()

-- The project root is the git root, not the nearest package (lspconfig's defaults look for lockfiles):
-- https://neovim.discourse.group/t/slow-lsp-on-large-ts-monorepo-project-caching/2668/2
-- Outside a git repo the file's own directory is used (single-file mode, as with the old lspconfig).
M.root_dir = function(bufnr, on_dir)
  local root = vim.fs.root(bufnr, '.git') or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  on_dir(root)
end

local format_group = vim.api.nvim_create_augroup('Format', { clear = true })

-- Called from the LspAttach autocmd (lspconfig/init.lua) for every client, so the servers'
-- own on_attach (e.g. eslint's LspEslintFixAll command) stay untouched.
M.on_attach = function(client, bufnr)
  keymaps_module.setup_keymaps(bufnr)

  -- formatting
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })
    vim.api.nvim_create_autocmd('BufWritePre', {
      group = format_group,
      buffer = bufnr,
      callback = function() vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 3000 }) end
    })
  end
end

return M
