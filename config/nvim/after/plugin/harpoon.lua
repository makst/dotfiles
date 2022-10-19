local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
  return
end

local h_status_ok, harpoon = pcall(require, "harpoon")
if not h_status_ok then
  return
end
telescope.load_extension "harpoon"

local harpoon_ui = require("harpoon.ui");
local harpoon_mark = require("harpoon.mark");

vim.keymap.set('n', ';m', function()
  harpoon_ui.toggle_quick_menu()
end)

vim.keymap.set('n', ';n', function()
  harpoon_ui.nav_next()
end)

vim.keymap.set('n', '<leader>m', function()
  harpoon_mark.add_file()
end)
