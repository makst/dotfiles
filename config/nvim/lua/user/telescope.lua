local status, telescope = pcall(require, "telescope")
if (not status) then return end
local actions = require('telescope.actions')
local builtin = require('telescope.builtin')

local function telescope_buffer_dir()
  return vim.fn.expand('%:p:h')
end

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

vim.keymap.set('n', ';f', function()
  builtin.find_files({
    no_ignore = false,
    hidden = true
  })
end)

vim.keymap.set('n', ';a', function()
  builtin.find_files({
    no_ignore = true,
    hidden = true
  })
end)

vim.keymap.set('n', ';p', function()
  builtin.pickers()
end)

vim.keymap.set('n', ';g', function()
  builtin.git_files()
end)

vim.keymap.set('n', ';s', function()
  builtin.grep_string()
end)

vim.keymap.set('n', ';d', function()
  builtin.lsp_document_symbols()
end)

vim.keymap.set('n', ';c', function()
  builtin.resume()
end)

vim.keymap.set('n', ';r', function()
  builtin.live_grep()
end)

vim.keymap.set('n', ';b', function()
  builtin.buffers()
end)

vim.keymap.set('n', ';t', function()
  builtin.help_tags()
end)

vim.keymap.set('n', ';;', function()
  builtin.resume()
end)

vim.keymap.set('n', ';e', function()
  builtin.diagnostics()
end)

vim.keymap.set('n', ';q', function()
  builtin.quickfix()
end)

vim.keymap.set("n", "sf", function()
  telescope.extensions.file_browser.file_browser({
    path = "%:p:h",
    cwd = telescope_buffer_dir(),
    respect_gitignore = false,
    hidden = true,
    grouped = true,
    previewer = false,
    initial_mode = "normal",
    layout_config = { height = 40 }
  })
end)
