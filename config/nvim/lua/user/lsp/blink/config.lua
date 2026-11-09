-- completion: blink.cmp, with the language server, file paths, snippets and words in the buffer as sources.
-- Snippets are friendly-snippets, expanded by nvim's own vim.snippet. blink.cmp also hands its capabilities
-- to every language server (its plugin/ file calls vim.lsp.config('*')). Loaded by user/lsp/blink/init.lua.
local status, blink = pcall(require, 'blink.cmp')
if (not status) then return end

blink.setup({
  keymap = require('user.lsp.blink.keymaps'),
  completion = {
    list = { selection = { preselect = false, auto_insert = true } },
    menu = { border = 'rounded' },
    documentation = { auto_show = true, window = { border = 'rounded' } },
    ghost_text = { enabled = true, show_without_selection = true },
  },
  signature = { enabled = true, window = { border = 'rounded' } },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      snippets = { opts = { extended_filetypes = { typescript = { 'javascript' } } } },
    },
  },
})
