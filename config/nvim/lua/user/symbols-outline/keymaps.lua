---@diagnostic disable-next-line: unused-local
local status, symbols_outline = pcall(require, "symbols-outline")
if (not status) then return end

local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>so', '<Cmd>SymbolsOutline<CR>', opts)
