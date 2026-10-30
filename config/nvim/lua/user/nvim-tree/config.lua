local status, nvim_tree = pcall(require, 'nvim-tree')
if (not status) then return end

-- `view.mappings` was removed from nvim-tree: mappings are set in on_attach now
local function on_attach(bufnr)
  local api = require('nvim-tree.api')
  api.config.mappings.default_on_attach(bufnr)
  vim.keymap.set('n', 'l', api.node.open.edit, { buffer = bufnr, nowait = true, desc = 'nvim-tree: open' })
end

nvim_tree.setup {
  on_attach = on_attach,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
  },
  view = {
    adaptive_size = true,
    side = "right",
  }
}
