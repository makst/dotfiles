local status, telescope = pcall(require, 'telescope')
if (not status) then return end

local telescope_keymaps = require('user.telescope.keymaps')

-- telescope's own count, a column in from the border, as fzf's
local default_status_text = require('telescope.config').values.get_status_text

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
    -- as the fzf pickers in the shell and tmux: the prompt on top, the list under it, the preview at the bottom
    layout_strategy = 'vertical',
    layout_config = { vertical = { prompt_position = 'top', mirror = true } },
    sorting_strategy = 'ascending',
    -- fzf's markers, a column in from the border as in fzf
    prompt_prefix = ' > ',
    selection_caret = ' ▌ ',
    entry_prefix = '   ',
    get_status_text = function(self, opts) return default_status_text(self, opts) .. ' ' end,
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
