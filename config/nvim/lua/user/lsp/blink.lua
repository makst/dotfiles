-- completion: blink.cmp, with the language server, file paths, snippets and words in the buffer as sources.
-- Snippets are friendly-snippets, expanded by nvim's own vim.snippet. blink.cmp also hands its capabilities
-- to every language server (its plugin/ file calls vim.lsp.config('*')).
local status, blink = pcall(require, 'blink.cmp')
if (not status) then return end

-- Tab opens the menu only after a word, so it still indents at the start of a line
local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

blink.setup({
  keymap = {
    preset = 'none',
    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<Tab>'] = {
      'select_next',
      'snippet_forward',
      function(cmp) if has_words_before() then return cmp.show() end end,
      'fallback',
    },
    ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
    -- accepts the first item when none is selected
    ['<CR>'] = { 'select_and_accept', 'fallback' },
    ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'fallback' },
    ['<C-h>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-l>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-j>'] = { 'snippet_forward', 'fallback' },
    ['<C-k>'] = { 'snippet_backward', 'fallback' },
  },
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
