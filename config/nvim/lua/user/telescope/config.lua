local status, telescope = pcall(require, "telescope")
if (not status) then return end
local actions = require('telescope.actions')

telescope.setup {
  defaults = {
    layout_strategy = "vertical",
    cache_picker = {
      num_pickers = 100
    },
    path_display = { "smart" },
    mappings = {
      n = {
        ['q'] = actions.close,
      },
    },
  },
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown {}
    }
  },
}

telescope.load_extension("fzf")
telescope.load_extension("ui-select")

