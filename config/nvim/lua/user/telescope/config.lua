local status, telescope = pcall(require, 'telescope')
if (not status) then return end
local telescope_keymaps = require('user.telescope.keymaps')

telescope.setup {
  pickers = {
    live_grep = {
      ---@diagnostic disable-next-line: unused-local
      additional_args = function(opts)
        return { '--hidden' }
      end
    },
    grep_string = {
      ---@diagnostic disable-next-line: unused-local
      additional_args = function(opts)
        return { '--hidden' }
      end
    },
  },
  defaults = {
    layout_strategy = 'vertical',
    cache_picker = {
      num_pickers = 100
    },
    mappings = telescope_keymaps.get_mappings()
  },
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown {}
    },
    project = {
      hidden_files = true, -- default: false
      theme = 'dropdown',
      order_by = 'asc',
      sync_with_nvim_tree = true, -- default false
    }
  },
}

telescope.load_extension('fzf')
telescope.load_extension('ui-select')
telescope.load_extension('project')
