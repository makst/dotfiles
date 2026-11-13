-- The TypeScript / JavaScript language server. Loaded by lspconfig/init.lua.
local base = require('user.lsp.lspconfig.base')

-- The nearest folder with node_modules/typescript (base.package_root); without one, the git root as for
-- every other server (base.lua).
local function root_dir(bufnr, on_dir)
  local root = base.package_root(bufnr, 'typescript')
  if root then
    on_dir(root)
  else
    base.root_dir(bufnr, on_dir)
  end
end

vim.lsp.config('ts_ls', {
  root_dir = root_dir,
  cmd = { 'typescript-language-server', '--stdio' },
})
vim.lsp.enable('ts_ls')
