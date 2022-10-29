local status, telescope = pcall(require, 'telescope')
if (not status) then return end

local telescope_keymaps = require('user.telescope.keymaps')
local chsh_term = require('user.toggleterm.cheatsheet_term')

local function open_chsh_term(prompt_bufnr)
  -- Get the full path
  local content = require('telescope.actions.state').get_selected_entry()
  local full_path = content.cwd .. require('plenary.path').path.sep .. content.value

  -- Close the Telescope window
  require('telescope.actions').close(prompt_bufnr)

  -- Open the file with VisiData
  chsh_term.open(full_path)
end

telescope.setup {
  pickers = {
    find_files = {
      mappings = {
        n = {
          ['t'] = open_chsh_term,
        }
      }
    },
    git_files = {
      mappings = {
        n = {
          ['t'] = open_chsh_term,
        }
      }
    },
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
