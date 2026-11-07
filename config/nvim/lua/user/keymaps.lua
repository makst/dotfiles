-- The keys that belong to no plugin: editing, splits, quit. Loaded by config/nvim/init.lua; a plugin's keys
-- are in user/<plugin>/keymaps.lua.
vim.g.mapleader = ','
local keymap = vim.keymap

keymap.set('i', 'jj', '<Esc>', { desc = 'Edit: leave insert mode' })

-- Do not yank with x
keymap.set('n', 'x', '"_x', { desc = 'Edit: delete a character without yanking it' })

-- Quit/Save file
keymap.set('n', '<leader>q', ':q!<Return>', { desc = 'File: quit without saving' })
keymap.set('n', '<leader>w', ':w!<Return>', { desc = 'File: save' })

-- Buffers
keymap.set('n', '<leader>bb', ':b#<Return>', { desc = 'Buffer: back to the last one' })
keymap.set('n', '<leader>bd', ':bd<Return>', { desc = 'Buffer: close this one' })
keymap.set('n', '<leader>bls', ':ls<Return>', { desc = 'Buffer: list them' })
-- https://stackoverflow.com/a/42071865
-- %bd = delete all buffers, e# = open the last buffer for editing, bd# to delete the [No Name] buffer that
-- gets created. The pipe in between does one command after another.
keymap.set('n', '<leader>bdr', ':%bd|e#|bd#<Return>', { desc = 'Buffer: close all but this one' })

-- Split window
keymap.set('n', '<leader>ss', ':split<Return><C-w>w', { desc = 'Split: below' })
keymap.set('n', '<leader>sv', ':vsplit<Return><C-w>w', { desc = 'Split: to the right' })
-- Zoom and equal sizes, as the other layers (`docs/design.md`, "Same key, every layer"): ,z makes the split
-- as big as it gets (CTRL-W _ and |) and, again, puts the layout back as it was; ,= makes all splits equal
-- (CTRL-W =)
keymap.set('n', '<leader>z', function()
  if vim.t.zoom_restore then
    vim.cmd(vim.t.zoom_restore)
    vim.t.zoom_restore = nil
  else
    vim.t.zoom_restore = vim.fn.winrestcmd()
    vim.cmd('wincmd _ | wincmd |')
  end
end, { desc = 'Split: zoom, and back' })
keymap.set('n', '<leader>=', '<C-w>=', { desc = 'Split: all the same size' })

-- Move window. Space cycles splits, Backspace goes back to the last one; the other layers follow the same
-- pattern (`docs/design.md`, "Same key, every layer").
keymap.set('n', '<Space>', '<C-w>w', { desc = 'Split: the next one, cycling' })
keymap.set('n', '<BS>', '<C-w>p', { desc = 'Split: back to the last one' })
keymap.set('', '<leader>sh', '<C-w>h', { desc = 'Split: the one to the left' })
keymap.set('', '<leader>sk', '<C-w>k', { desc = 'Split: the one above' })
keymap.set('', '<leader>sj', '<C-w>j', { desc = 'Split: the one below' })
keymap.set('', '<leader>sl', '<C-w>l', { desc = 'Split: the one to the right' })

-- Resize window: the arrows as h/j/k/l, as Shift+h/j/k/l on the other layers (H J K L are treewalker's here):
-- left / right narrower / wider, up / down shorter / taller
keymap.set('n', '<left>', '<C-w><', { desc = 'Split: narrower' })
keymap.set('n', '<right>', '<C-w>>', { desc = 'Split: wider' })
keymap.set('n', '<up>', '<C-w>-', { desc = 'Split: shorter' })
keymap.set('n', '<down>', '<C-w>+', { desc = 'Split: taller' })

-- clear search highlights (CTRL-L moves to the right nvim/tmux pane, see vim-tmux-navigator)
keymap.set('n', '<Esc>', '<cmd>:noh<cr>', { desc = 'Search: clear the highlights' })

keymap.set('n', '<leader>re', '<cmd>lua reload_nvim_conf()<cr>', { desc = 'Config: reload it' })

-- diff 2 buffers in a split: on
keymap.set('n', '<leader>dt', '<cmd>:windo diffthis<cr>', { desc = 'Diff: the splits against each other' })

-- diff 2 buffers in a split: off
keymap.set('n', '<leader>do', '<cmd>:windo diffoff<cr>', { desc = 'Diff: off' })

-- nvim's default LSP maps (gra, gri, grn, grr, grt, grx) make `gr` (Trouble references) wait for a
-- third key; code action and rename are on ga / ,rn already
for _, lhs in ipairs({ 'gra', 'gri', 'grn', 'grr', 'grt', 'grx' }) do
  pcall(vim.keymap.del, 'n', lhs)
end
pcall(vim.keymap.del, 'x', 'gra')
