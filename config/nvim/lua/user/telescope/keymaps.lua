---@diagnostic disable-next-line: unused-local
local status, telescope = pcall(require, 'telescope')
if (not status) then return end
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

local M = {}

M.get_mappings = function()
  return {
    i = {
      ['<C-s>'] = actions.send_selected_to_qflist + actions.open_qflist
    },
    n = {
      ['q'] = actions.close,
      ['<C-s>'] = actions.send_selected_to_qflist + actions.open_qflist
    },
  }
end

vim.keymap.set('n', ';f', function()
  builtin.find_files({
    no_ignore = false,
    hidden = true
  })
end, { desc = 'Find: files (not ignored ones)' })

vim.keymap.set('n', ';a', function()
  builtin.find_files({
    no_ignore = true,
    hidden = true
  })
end, { desc = 'Find: all files, ignored ones too' })

vim.keymap.set('n', ';p', function()
  require('telescope').extensions.project.project {}
end, { desc = 'Find: projects' })

vim.keymap.set('n', ';g', function()
  builtin.git_files()
end, { desc = 'Find: files in git' })

vim.keymap.set('n', ';s', function()
  builtin.grep_string()
end, { desc = 'Find: the word under the cursor' })

vim.keymap.set('n', ';d', function()
  builtin.lsp_document_symbols()
end, { desc = 'Find: symbols in this file' })

vim.keymap.set('n', ';w', function()
  builtin.lsp_dynamic_workspace_symbols()
end, { desc = 'Find: symbols in the project' })

vim.keymap.set('n', ';c', function()
  builtin.resume()
end, { desc = 'Find: back to the last picker' })

vim.keymap.set('n', ';r', function()
  builtin.live_grep()
end, { desc = 'Find: grep the project' })

vim.keymap.set('n', ';b', function()
  builtin.buffers()
end, { desc = 'Find: open buffers' })

vim.keymap.set('n', ';t', function()
  builtin.help_tags()
end, { desc = 'Find: help' })

vim.keymap.set('n', ';;', function()
  builtin.resume()
end, { desc = 'Find: back to the last picker' })

vim.keymap.set('n', ';e', function()
  builtin.diagnostics()
end, { desc = 'Find: diagnostics' })

vim.keymap.set('n', ';q', function()
  builtin.quickfix()
end, { desc = 'Find: the quickfix list' })

-- ;?: every key that has a desc, searchable by key or by what it does (each desc starts with its area, e.g.
-- "Git:", "Split:"), nvim's own built-in keys included. Buffer-local keys (LSP, the file tree) show in the
-- buffers that have them. `?` lists the keys in tmux (C-a ?), lazygit and telescope's normal mode too.
vim.keymap.set('n', ';?', function()
  builtin.keymaps({
    modes = { 'n', 'x', 'o', 'i', 't' },
    show_plug = false,
    filter = function(keymap) return keymap.desc ~= nil and keymap.desc ~= '' end,
  })
end, { desc = 'Find: keys, by key or by what they do' })

return M;
