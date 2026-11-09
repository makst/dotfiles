-- blink.cmp's keys in the completion menu; config.lua passes them to setup (blink.cmp takes its keys only
-- there). C-h/l scroll the docs and C-j/k step through a snippet: insert mode only, so the C-h/j/k/l of tmux
-- panes and nvim splits (normal mode) don't meet them.

-- Tab opens the menu only after a word, so it still indents at the start of a line
local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

return {
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
  ['<C-e>'] = { 'hide', 'fallback' },
  ['<C-h>'] = { 'scroll_documentation_up', 'fallback' },
  ['<C-l>'] = { 'scroll_documentation_down', 'fallback' },
  ['<C-j>'] = { 'snippet_forward', 'fallback' },
  ['<C-k>'] = { 'snippet_backward', 'fallback' },
}
