-- Same keys as the old tree-climber setup
vim.keymap.set({ 'n', 'v' }, 'H', '<cmd>Treewalker Left<cr>',
  { silent = true, desc = 'Syntax tree: out, to the parent' })
vim.keymap.set({ 'n', 'v' }, 'L', '<cmd>Treewalker Right<cr>',
  { silent = true, desc = 'Syntax tree: in, to the first child' })
vim.keymap.set({ 'n', 'v' }, 'J', '<cmd>Treewalker Down<cr>',
  { silent = true, desc = 'Syntax tree: the next node' })
vim.keymap.set({ 'n', 'v' }, 'K', '<cmd>Treewalker Up<cr>',
  { silent = true, desc = 'Syntax tree: the previous node' })
vim.keymap.set('n', '<leader>k', '<cmd>Treewalker SwapUp<cr>',
  { silent = true, desc = 'Syntax tree: swap the node with the one above' })
vim.keymap.set('n', '<leader>j', '<cmd>Treewalker SwapDown<cr>',
  { silent = true, desc = 'Syntax tree: swap the node with the one below' })

-- Treewalker has no "highlight node" or "select node" commands; use nvim's treesitter instead.
-- In visual mode nvim 0.12 has `an` / `in` (parent / child node) built in, see :h treesitter-incremental-selection
local ns = vim.api.nvim_create_namespace('user_highlight_node')

-- nvim 0.12 parses asynchronously; make sure the tree is current before asking for a node
local function node_at_cursor()
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if ok and parser then parser:parse() end
  return vim.treesitter.get_node()
end
vim.keymap.set('n', '<leader>hn', function()
  local node = node_at_cursor()
  if not node then return end
  local sr, sc, er, ec = node:range()
  vim.hl.range(0, ns, 'Visual', { sr, sc }, { er, ec }, { timeout = 500 })
end, { silent = true, desc = 'Syntax tree: flash the node under the cursor' })

-- `in` as an operator target (din, yin, cin): the node under the cursor
vim.keymap.set('o', 'in', function()
  local node = node_at_cursor()
  if not node then return end
  local sr, sc, er, ec = node:range()
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd('normal! v')
  vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
end, { silent = true, desc = 'Syntax tree: the node under the cursor (din, yin, cin)' })
