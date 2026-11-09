-- How diagnostics look (signs, no virtual text, rounded floats), and the keys bound once a server attaches.
-- Loaded by lspconfig/init.lua.
local icons_module = require('user.lsp.lspconfig.icons')

-- signs in the number column; the icons are nerd font glyphs, see icons.lua
local severity = vim.diagnostic.severity
local sign_text, sign_numhl = {}, {}
for type, severity_id in pairs({ Error = severity.ERROR, Warn = severity.WARN, Hint = severity.HINT, Info = severity.INFO }) do
  sign_text[severity_id] = icons_module.icons[type]
  sign_numhl[severity_id] = 'DiagnosticSign' .. type
end

vim.diagnostic.config({
  virtual_lines = false,
  virtual_text = false,
  signs = {
    text = sign_text,
    texthl = sign_numhl,
    numhl = sign_numhl,
  },
  float = {
    border = 'rounded',
  },
})

-- disables diagnostics for buffers with filetype helm
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'helm',
  callback = function(args) vim.diagnostic.enable(false, { bufnr = args.buf }) end,
})

-- rounded borders for hover, signature help and other floats (replaces the deprecated vim.lsp.with)
vim.o.winborder = 'rounded'

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

-- the keys and settings of base.on_attach, in every buffer a server attaches to. The servers themselves are
-- the files next to this one (nvim 0.11+ API: vim.lsp.config() merges over the defaults that nvim-lspconfig
-- ships in lsp/*.lua, vim.lsp.enable() starts the server); completion capabilities come from blink.cmp.
local base = require('user.lsp.lspconfig.base')
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspAttach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then base.on_attach(client, args.buf) end
  end,
})
