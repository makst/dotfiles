-- harpoon's keys: ,m marks a file, ;m lists the marks, ;j / ;k walk them. Loaded by user/harpoon/init.lua.
local status_ok, harpoon = pcall(require, 'harpoon')
if (not status_ok) then return end

vim.keymap.set('n', ';m', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = 'Harpoon: the marked files' })

vim.keymap.set('n', ';j', function()
  harpoon:list():next()
end, { desc = 'Harpoon: the next marked file' })

vim.keymap.set('n', ';k', function()
  harpoon:list():prev()
end, { desc = 'Harpoon: the previous marked file' })

vim.keymap.set('n', '<leader>m', function()
  harpoon:list():add()
end, { desc = 'Harpoon: mark this file' })
