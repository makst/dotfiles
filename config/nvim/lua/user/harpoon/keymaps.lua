---@diagnostic disable-next-line: unused-local
local status_ok, harpoon = pcall(require, "harpoon")
if (not status_ok) then return end

local harpoon_ui = require("harpoon.ui");
local harpoon_mark = require("harpoon.mark");

vim.keymap.set('n', ';m', function()
  harpoon_ui.toggle_quick_menu()
end)

vim.keymap.set('n', ';j', function()
  harpoon_ui.nav_next()
end)

vim.keymap.set('n', ';k', function()
  harpoon_ui.nav_prev()
end)

vim.keymap.set('n', '<leader>m', function()
  harpoon_mark.add_file()
end)
