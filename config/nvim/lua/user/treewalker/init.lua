local status, treewalker = pcall(require, 'treewalker')
if (not status) then return end

treewalker.setup {
  highlight = true, -- briefly highlight the node after a jump
}
require('user.treewalker.keymaps')
