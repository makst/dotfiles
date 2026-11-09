-- treewalker.nvim's setup. Loaded by user/treewalker/init.lua.
local status, treewalker = pcall(require, 'treewalker')
if (not status) then return end

treewalker.setup {
  highlight = true, -- briefly highlight the node after a jump
}
