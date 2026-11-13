-- The eslint language server, and eslint's fixes on save. Loaded by lspconfig/init.lua.
local base = require('user.lsp.lspconfig.base')

-- The nearest folder with node_modules/eslint (base.package_root), where the server loads the project's
-- ESLint from. Without one the project doesn't use ESLint and no server starts, instead of one that only
-- says "Unable to find ESLint library".
local function root_dir(bufnr, on_dir)
  local root = base.package_root(bufnr, 'eslint')
  if root then
    on_dir(root)
  end
end

vim.lsp.config('eslint', { root_dir = root_dir })
vim.lsp.enable('eslint')

-- eslint format on save (LspEslintFixAll is defined by the eslint config's on_attach)
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.tsx', '*.ts', '*.jsx', '*.js' },
  command = 'silent! LspEslintFixAll',
  group = vim.api.nvim_create_augroup('MyAutocmdsJavaScripFormatting', {}),
})
