---@diagnostic disable-next-line: unused-local
local status, nvim_tree = pcall(require, 'nvim-tree')
if (not status) then return {} end

local M = {}

-- on_attach(bufnr): the keys inside a tree buffer, nvim-tree's defaults plus `l` to open; config.lua passes it
-- to setup (nvim-tree sets buffer keys only through on_attach)
function M.on_attach(bufnr)
  local api = require('nvim-tree.api')
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'l', api.node.open.edit, { buffer = bufnr, nowait = true, desc = 'File tree: open' })
end

vim.keymap.set('n', '<leader>e', '<Cmd>NvimTreeToggle<CR>', { silent = true, desc = 'File tree: show / hide' })
vim.keymap.set('n', '<leader>f', '<Cmd>NvimTreeFindFileToggle<CR>', { silent = true, desc = 'File tree: this file in it' })

return M
