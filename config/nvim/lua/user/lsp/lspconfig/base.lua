-- What every language server here shares: the project root and the keys once one attaches. Loaded by
-- lspconfig/config.lua and the server files next to it.
local keymaps_module = require('user.lsp.lspconfig.keymaps')
local M = {}

-- The project root is the git root, not the nearest package (lspconfig's defaults look for lockfiles):
-- https://neovim.discourse.group/t/slow-lsp-on-large-ts-monorepo-project-caching/2668/2
-- Outside a git repo the file's own directory is used (single-file mode, as with the old lspconfig).
M.root_dir = function(bufnr, on_dir)
  local root = vim.fs.root(bufnr, '.git') or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
  on_dir(root)
end

-- Usage: M.package_root(bufnr, 'typescript') → path or nil
-- The nearest folder above the buffer whose node_modules has the package. Servers that load a project's own
-- package (ts_ls, eslint) look for it only in <root>/node_modules, so with the git root as root a project in
-- a subfolder of its repo (infra/, web/) finds nothing; a monorepo with hoisted node_modules still gets the top.
M.package_root = function(bufnr, package)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local found = vim.fs.find('node_modules/' .. package, { upward = true, path = vim.fs.dirname(file) })[1]
  return found and vim.fs.dirname(vim.fs.dirname(found))
end

-- Called from the LspAttach autocmd (lspconfig/config.lua) for every client, so the servers'
-- own on_attach (e.g. eslint's LspEslintFixAll command) stay untouched.
-- Formatting on save is conform.nvim's (user/conform.lua).
M.on_attach = function(_client, bufnr)
  keymaps_module.setup_keymaps(bufnr)
end

return M
