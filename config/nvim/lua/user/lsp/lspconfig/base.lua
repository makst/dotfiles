local keymaps_module = require('user.lsp.lspconfig.keymaps')
local M = {}

-- The project root is the git root, not the nearest package (lspconfig's defaults look for lockfiles):
-- https://neovim.discourse.group/t/slow-lsp-on-large-ts-monorepo-project-caching/2668/2
-- Outside a git repo the file's own directory is used (single-file mode, as with the old lspconfig).
M.root_dir = function(bufnr, on_dir)
  local root = vim.fs.root(bufnr, '.git') or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  on_dir(root)
end

-- Called from the LspAttach autocmd (lspconfig/init.lua) for every client, so the servers'
-- own on_attach (e.g. eslint's LspEslintFixAll command) stay untouched.
-- Formatting on save is conform.nvim's (user/conform.lua).
M.on_attach = function(_client, bufnr)
  keymaps_module.setup_keymaps(bufnr)
end

return M
