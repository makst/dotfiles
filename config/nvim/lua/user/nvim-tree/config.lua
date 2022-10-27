local status, nvim_tree = pcall(require, "nvim-tree")
if (not status) then return end

nvim_tree.setup {
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
  },
  view = {
    adaptive_size = true,
    mappings = {
      list = {
        { key = "l", action = "edit" }
      }
    }
  }
}
