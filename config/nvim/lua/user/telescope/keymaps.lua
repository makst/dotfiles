---@diagnostic disable-next-line: unused-local
local status, telescope = pcall(require, "telescope")
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

vim.keymap.set('n', ';w', function()
  builtin.lsp_dynamic_workspace_symbols()
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

return M;
