-- nvim-tree's setup: the file tree on the right. Loaded by user/nvim-tree/init.lua.
local status, nvim_tree = pcall(require, 'nvim-tree')
if (not status) then return end

nvim_tree.setup {
  -- the tree's own keys, in each tree buffer (keymaps.lua)
  on_attach = require('user.nvim-tree.keymaps').on_attach,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
  },
  view = {
    adaptive_size = true,
    side = "right",
  }
}
