local icons_module = require('user.lsp.lspconfig.icons')

for type, icon in pairs(icons_module.icons) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = false,
  signs = {
    active = icons_module.icons,
  },
  float = {
    border = 'rounded',
  },
})

-- disables diagnostics for buffers with filetype helm
vim.cmd([[
  autocmd FileType helm lua vim.diagnostic.disable(vim.fn.bufnr())
]])


vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'rounded',
})

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = 'rounded',
})

-- https://vi.stackexchange.com/questions/38038/how-to-change-background-color-of-the-text-of-hover-window
local set_hl_for_floating_window = function()
  vim.api.nvim_set_hl(0, 'NormalFloat', {
    link = 'Normal',
  })
  vim.api.nvim_set_hl(0, 'FloatBorder', {
    bg = 'none',
  })
end

set_hl_for_floating_window()

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  desc = 'Avoid overwritten by loading color schemes later',
  callback = set_hl_for_floating_window,
})
