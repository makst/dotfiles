vim.g.mapleader = ','
local keymap = vim.keymap

keymap.set('i', 'jj', '<Esc>')

-- Do not yank with x
keymap.set('n', 'x', '"_x')

-- Quit/Save file
keymap.set('n', '<leader>q', ':q!<Return>')
keymap.set('n', '<leader>w', ':w!<Return>')

-- Buffers
keymap.set('n', '<leader>bb', ':b#<Return>')
keymap.set('n', '<leader>bd', ':bd<Return>')
keymap.set('n', '<leader>bls', ':ls<Return>')
-- https://stackoverflow.com/a/42071865
-- %bd = delete all buffers, e# = open the last buffer for editing, bd# to delete the [No Name] buffer that
-- gets created. The pipe in between does one command after another.
keymap.set('n', '<leader>bdr', ':%bd|e#|bd#<Return>')

-- Split window
keymap.set('n', '<leader>ss', ':split<Return><C-w>w')
keymap.set('n', '<leader>sv', ':vsplit<Return><C-w>w')
-- Zoom and equal sizes, as the other layers (README, "Same key, every layer"): ,z makes the split as big as
-- it gets (CTRL-W _ and |) and, again, puts the layout back as it was; ,= makes all splits equal (CTRL-W =)
keymap.set('n', '<leader>z', function()
  if vim.t.zoom_restore then
    vim.cmd(vim.t.zoom_restore)
    vim.t.zoom_restore = nil
  else
    vim.t.zoom_restore = vim.fn.winrestcmd()
    vim.cmd('wincmd _ | wincmd |')
  end
end)
keymap.set('n', '<leader>=', '<C-w>=')

-- Move window. Space cycles splits, Backspace goes back to the last one; the other layers follow the same
-- pattern (README, "Same key, every layer").
keymap.set('n', '<Space>', '<C-w>w')
keymap.set('n', '<BS>', '<C-w>p')
keymap.set('', '<leader>sh', '<C-w>h')
keymap.set('', '<leader>sk', '<C-w>k')
keymap.set('', '<leader>sj', '<C-w>j')
keymap.set('', '<leader>sl', '<C-w>l')

-- Resize window: the arrows as h/j/k/l, as Shift+h/j/k/l on the other layers (H J K L are treewalker's here):
-- left / right narrower / wider, up / down shorter / taller
keymap.set('n', '<left>', '<C-w><')
keymap.set('n', '<right>', '<C-w>>')
keymap.set('n', '<up>', '<C-w>-')
keymap.set('n', '<down>', '<C-w>+')

-- clear search highlights (CTRL-L moves to the right nvim/tmux pane, see vim-tmux-navigator)
keymap.set('n', '<Esc>', '<cmd>:noh<cr>')

keymap.set('n', '<leader>re', '<cmd>lua reload_nvim_conf()<cr>')

-- diff 2 buffers in a split: on
keymap.set('n', '<leader>dt', '<cmd>:windo diffthis<cr>')

-- diff 2 buffers in a split: off
keymap.set('n', '<leader>do', '<cmd>:windo diffoff<cr>')

-- nvim's default LSP maps (gra, gri, grn, grr, grt, grx) make `gr` (Trouble references) wait for a
-- third key; code action and rename are on ga / ,rn already
for _, lhs in ipairs({ 'gra', 'gri', 'grn', 'grr', 'grt', 'grx' }) do
  pcall(vim.keymap.del, 'n', lhs)
end
pcall(vim.keymap.del, 'x', 'gra')
