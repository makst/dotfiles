-- The TypeScript / JavaScript language server. Loaded by lspconfig/init.lua.
local base = require('user.lsp.lspconfig.base')

-- typescript-language-server looks for TypeScript only in <root>/node_modules, so the root is the nearest
-- folder that has node_modules/typescript: a project in a subfolder of its repo (infra/, web/) gets its own
-- TypeScript, and a monorepo with hoisted node_modules still gets one server at the top. Without one, the
-- git root as for every other server (base.lua).
local function root_dir(bufnr, on_dir)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local typescript = vim.fs.find('node_modules/typescript', { upward = true, path = vim.fs.dirname(file) })[1]
  if typescript then
    on_dir(vim.fs.dirname(vim.fs.dirname(typescript)))
  else
    base.root_dir(bufnr, on_dir)
  end
end

vim.lsp.config('ts_ls', {
  root_dir = root_dir,
  cmd = { 'typescript-language-server', '--stdio' },
})
vim.lsp.enable('ts_ls')
