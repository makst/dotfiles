local status, oil = pcall(require, 'oil')
if (not status) then return end

oil.setup({
  -- `vim .` and `:e dir/` stay with nvim-tree; oil opens only with -
  default_file_explorer = false,
  -- deleted files go to the macOS trash, not straight away
  delete_to_trash = true,
  -- reload when files change on disk (agents, git), so no refresh key is needed
  watch_for_changes = true,
  view_options = { show_hidden = true },
  keymaps = {
    -- C-h / C-l move between nvim splits and tmux panes; C-s (vertical split) stays
    ['<C-h>'] = false,
    ['<C-l>'] = false,
  },
})
