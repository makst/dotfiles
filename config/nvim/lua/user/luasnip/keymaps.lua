---@diagnostic disable-next-line: unused-local
local status, _luasnip = pcall(require, 'luasnip')
if (not status) then return end

local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }
keymap('i', '<c-j>', '<cmd>lua require"luasnip".jump(1)<CR>', opts)
keymap('s', '<c-j>', '<cmd>lua require"luasnip".jump(1)<CR>', opts)
keymap('i', '<c-k>', '<cmd>lua require"luasnip".jump(-1)<CR>', opts)
keymap('s', '<c-k>', '<cmd>lua require"luasnip".jump(-1)<CR>', opts)
