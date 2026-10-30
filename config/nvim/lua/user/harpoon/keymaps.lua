local status_ok, harpoon = pcall(require, 'harpoon')
if (not status_ok) then return end

vim.keymap.set('n', ';m', function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end)

vim.keymap.set('n', ';j', function()
  harpoon:list():next()
end)

vim.keymap.set('n', ';k', function()
  harpoon:list():prev()
end)

vim.keymap.set('n', '<leader>m', function()
  harpoon:list():add()
end)
