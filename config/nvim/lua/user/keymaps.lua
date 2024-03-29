vim.g.mapleader = ','
local keymap = vim.keymap

keymap.set('i', 'jj', '<Esc>')

-- Do not yank with x
keymap.set('n', 'x', '"_x')

-- Quit/Save file
keymap.set('n', '<leader>q', ':q!<Return>')
keymap.set('n', '<leader>w', ':w!<Return>')

-- Buffers
keymap.set('n', '<leader>bn', ':bn<Return>')
keymap.set('n', '<leader>bp', ':bp<Return>')
keymap.set('n', '<leader>bb', ':b#<Return>')
keymap.set('n', '<leader>bd', ':bd<Return>')
keymap.set('n', '<leader>bls', ':ls<Return>')
-- https://stackoverflow.com/a/42071865
-- %bd = delete all buffers, e# = open the last buffer for editing, bd# to delete the [No Name] buffer that gets created.
-- The pipe in between does one command after another.
keymap.set('n', '<leader>bdr', ':%bd|e#|bd#<Return>')

-- Split window
keymap.set('n', '<leader>ss', ':split<Return><C-w>w')
keymap.set('n', '<leader>sv', ':vsplit<Return><C-w>w')
-- CTRL-W + | Set current window width to N (default: widest possible)
-- CTRL-W + _ Set current window height to N (default: highest possible)
-- CTRL-W + = Make all windows (almost) equally high and wide
keymap.set('n', '<leader>zi', '<C-w>_|<C-w>|') -- zoom in
keymap.set('n', '<leader>zo', '<C-w>=') -- zoom out

-- Move window
keymap.set('n', '<Space>', '<C-w>w')
keymap.set('', '<leader>sh', '<C-w>h')
keymap.set('', '<leader>sk', '<C-w>k')
keymap.set('', '<leader>sj', '<C-w>j')
keymap.set('', '<leader>sl', '<C-w>l')

-- Resize window
keymap.set('n', '<left>', '<C-w><')
keymap.set('n', '<right>', '<C-w>>')
keymap.set('n', '<up>', '<C-w>+')
keymap.set('n', '<down>', '<C-w>-')

-- clear search highlights
keymap.set('n', '<C-l>', '<cmd>:noh<cr>')

keymap.set('n', '<leader>re', '<cmd>lua reload_nvim_conf()<cr>')

-- diff 2 buffers in a split: on
keymap.set('n', '<leader>dt', '<cmd>:windo diffthis<cr>')

-- diff 2 buffers in a split: off
keymap.set('n', '<leader>do', '<cmd>:windo diffoff<cr>')
