-- The ; pickers and the keys inside every picker (user/fzf-lua/config passes picker_keys and file_actions to
-- fzf-lua's setup). Normal mode in a picker (jj, j/k, q) comes from config/tmux/picker.zsh, as in tmux.
local status, fzf = pcall(require, 'fzf-lua')
if (not status) then return {} end
local actions = require('fzf-lua.actions')

local M = {}

-- picker(name, opts, keys): user/fzf-lua/config's, which requires this file first
local function picker(...) return require('user.fzf-lua.config').picker(...) end

-- inside a picker. `true` keeps fzf-lua's other keys. The preview keys are fzfrc's, here because nvim draws
-- the preview, not fzf: C-/ shows / hides it, C-M-n / C-M-p scroll it half a page. C-n / C-p are left to fzf,
-- which moves to the next / previous line with them (fzfrc). C-/ is <C-_> inside tmux (no extended keys
-- there), <C-/> outside it.
M.picker_keys = {
  builtin = {
    true,
    ['<C-/>'] = 'toggle-preview',
    ['<C-_>'] = 'toggle-preview',
    ['<C-M-n>'] = 'preview-half-page-down',
    ['<C-M-p>'] = 'preview-half-page-up',
  },
}

-- ? in normal mode lists the keys (picker_modes in config/tmux/picker.zsh presses f1 for it, see
-- user/fzf-lua/config): fzf-lua's list, as its F1, which has the picker's own keys. fzf itself presses f1, so
-- it's an fzf action that calls nvim: F1's is nvim's, which fzf never sees.
M.help_actions = {
  ['f1'] = { fn = function() require('fzf-lua.win').toggle_help() end, exec_silent = true, desc = 'toggle-help' },
}

-- what a picked file (or grep match, symbol, buffer) opens in: C-s sends the marked ones (or the current one)
-- to the quickfix list and opens it, C-x / C-v a split / vertical split, C-t a tab
M.file_actions = {
  true,
  ['ctrl-s'] = actions.file_sel_to_qf,
  ['ctrl-x'] = actions.file_split,
}

-- ;b: as any file, and M-d (or d in normal mode, see ;b) closes the buffer, as in codetour's pickers;
-- fzf-lua's C-x for that is the split here
M.buffer_actions = {
  ['ctrl-x'] = actions.file_split,
  ['alt-d'] = { fn = actions.buf_del, reload = true },
}

vim.keymap.set('n', ';f', function()
  fzf.files(picker('files'))
end, { desc = 'Find: files (not ignored ones)' })

vim.keymap.set('n', ';a', function()
  fzf.files(picker('all files', { fd_opts = '--color=never --type f --type l --hidden --no-ignore --exclude .git' }))
end, { desc = 'Find: all files, ignored ones too' })

vim.keymap.set('n', ';g', function()
  fzf.git_files(picker('git files'))
end, { desc = 'Find: files in git' })

vim.keymap.set('n', ';s', function()
  fzf.grep_cword(picker('grep'))
end, { desc = 'Find: the word under the cursor' })

vim.keymap.set('n', ';d', function()
  fzf.lsp_document_symbols(picker('symbols'))
end, { desc = 'Find: symbols in this file' })

vim.keymap.set('n', ';w', function()
  fzf.lsp_live_workspace_symbols(picker('workspace symbols'))
end, { desc = 'Find: symbols in the project' })

vim.keymap.set('n', ';c', function()
  fzf.resume()
end, { desc = 'Find: back to the last picker' })

vim.keymap.set('n', ';r', function()
  fzf.live_grep(picker('grep'))
end, { desc = 'Find: grep the project' })

vim.keymap.set('n', ';b', function()
  fzf.buffers(picker('buffers', nil, 'd:alt-d'))
end, { desc = 'Find: open buffers' })

vim.keymap.set('n', ';t', function()
  fzf.helptags(picker('help'))
end, { desc = 'Find: help' })

vim.keymap.set('n', ';;', function()
  fzf.resume()
end, { desc = 'Find: back to the last picker' })

vim.keymap.set('n', ';e', function()
  fzf.diagnostics_workspace(picker('diagnostics'))
end, { desc = 'Find: diagnostics' })

vim.keymap.set('n', ';q', function()
  fzf.quickfix(picker('quickfix'))
end, { desc = 'Find: the quickfix list' })

-- ;?: every key that has a desc, searchable by key or by what it does (each desc starts with its area, e.g.
-- "Git:", "Split:"), nvim's own built-in keys included. Buffer-local keys (LSP, the file tree) show in the
-- buffers that have them. `?` lists the keys in tmux (C-a ?) and lazygit too. Enter presses the key.
vim.keymap.set('n', ';?', function()
  require('user.fzf-lua.config').keys()
end, { desc = 'Find: keys, by key or by what they do' })

return M
